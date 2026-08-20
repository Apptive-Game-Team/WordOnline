package com.wordonline.server.session.service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.wordonline.server.game.domain.SessionObject;
import com.wordonline.server.game.service.GameLoop;

import io.micrometer.core.instrument.MeterRegistry;

/**
 * Load-test instrumentation: what frame rate the running loops are actually achieving.
 *
 * <p>{@code deltaTime} alone cannot answer that. It holds the last <em>completed</em> frame, so a
 * loop that has been off the CPU for eight seconds still reports the 20 fps of the frame before
 * it stalled, and an average over such loops reads as healthy while the sessions are starving.
 * Each loop's frame rate is therefore taken over whichever is longer, its last frame or the time
 * since that frame ended, which decays a starved loop towards zero as it starves.
 *
 * <p>The tenth percentile is the number capacity work needs: a mean stays comfortable long after
 * the slowest sessions have become unplayable.
 */
@Component
public class LoopFpsMetrics {

    private static final long STALL_THRESHOLD_MS = 10_000;

    private final SessionService sessionService;

    private final AtomicInteger meanFpsCentis = new AtomicInteger();
    private final AtomicInteger p10FpsCentis = new AtomicInteger();
    private final AtomicInteger minFpsCentis = new AtomicInteger();
    private final AtomicInteger runningSessions = new AtomicInteger();
    private final AtomicInteger stalledSessions = new AtomicInteger();

    public LoopFpsMetrics(SessionService sessionService, MeterRegistry meterRegistry) {
        this.sessionService = sessionService;
        meterRegistry.gauge("wordonline.loop.fps.mean", meanFpsCentis, value -> value.get() / 100.0);
        meterRegistry.gauge("wordonline.loop.fps.p10", p10FpsCentis, value -> value.get() / 100.0);
        meterRegistry.gauge("wordonline.loop.fps.min", minFpsCentis, value -> value.get() / 100.0);
        meterRegistry.gauge("wordonline.loop.sessions", runningSessions);
        meterRegistry.gauge("wordonline.loop.stalled", stalledSessions);
    }

    @Scheduled(fixedDelayString = "${loop.fps.sample-interval-ms:2000}")
    public void sample() {
        Collection<SessionObject> sessions = sessionService.getSessionObjects();
        long now = System.currentTimeMillis();

        List<Double> rates = new ArrayList<>(sessions.size());
        double total = 0;
        int stalled = 0;
        for (SessionObject session : sessions) {
            GameLoop loop = session.getGameLoop();
            if (loop == null || !loop.is_running()) {
                continue;
            }
            long frameAgeMs = Math.max(0, now - loop.getLastFrameEndMillis());
            if (frameAgeMs >= STALL_THRESHOLD_MS) {
                stalled++;
            }
            double frameSeconds = Math.max(loop.getGameContext().getDeltaTime(), frameAgeMs / 1000.0);
            double fps = frameSeconds > 0 ? 1.0 / frameSeconds : 0.0;
            rates.add(fps);
            total += fps;
        }

        runningSessions.set(rates.size());
        stalledSessions.set(stalled);
        if (rates.isEmpty()) {
            meanFpsCentis.set(0);
            p10FpsCentis.set(0);
            minFpsCentis.set(0);
            return;
        }

        Collections.sort(rates);
        int p10Index = (int) Math.floor(0.1 * (rates.size() - 1));
        meanFpsCentis.set((int) Math.round(total / rates.size() * 100));
        p10FpsCentis.set((int) Math.round(rates.get(p10Index) * 100));
        minFpsCentis.set((int) Math.round(rates.get(0) * 100));
    }
}
