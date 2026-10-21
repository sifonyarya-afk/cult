"use client";

import { useEffect, useState } from "react";
import { Icon } from "./icon";
import { youtubeFor } from "@/lib/catalog";

export function Story({
  title,
  image,
  paragraphs,
  minutes,
}: {
  title: string;
  image: string;
  paragraphs: string[];
  minutes?: string;
}) {
  const [mode, setMode] = useState<"read" | "watch">("read");
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    if (!playing) return;
    const timer = window.setInterval(() => {
      setProgress((value) => {
        if (value >= 100) {
          setPlaying(false);
          return 100;
        }
        return value + 4;
      });
    }, 400);
    return () => window.clearInterval(timer);
  }, [playing]);

  return (
    <section>
      <div className="mb-4 flex rounded-full bg-surface-container p-1">
        <button
          className={`flex-1 rounded-full py-2 font-label-md ${mode === "read" ? "bg-on-background text-white" : "text-on-surface-variant"}`}
          onClick={() => setMode("read")}
        >
          Читать
        </button>
        <button
          className={`flex-1 rounded-full py-2 font-label-md ${mode === "watch" ? "bg-on-background text-white" : "text-on-surface-variant"}`}
          onClick={() => setMode("watch")}
        >
          Смотреть
        </button>
      </div>
      {mode === "read" ? (
        <div className="space-y-4">
          {paragraphs.map((paragraph) => (
            <p key={paragraph} className="font-body-md text-on-surface-variant">
              {paragraph}
            </p>
          ))}
        </div>
      ) : (
        <div>
          <button
            className="relative aspect-video w-full overflow-hidden rounded-xl"
            onClick={() => {
              if (progress >= 100) setProgress(0);
              setPlaying((value) => !value);
            }}
          >
            <img src={image} alt="" className="h-full w-full object-cover" />
            <span className="absolute inset-0 flex items-center justify-center bg-black/25">
              <span className="flex h-16 w-16 items-center justify-center rounded-full bg-white/90">
                <Icon name={playing ? "pause" : "play_arrow"} fill className="text-3xl text-on-background" />
              </span>
            </span>
            <span className="absolute right-3 bottom-3 left-3">
              <span className="mb-1 block text-left text-sm text-white">{title}</span>
              <span className="block h-1 overflow-hidden rounded-full bg-white/40">
                <span className="block h-full bg-white" style={{ width: `${progress}%` }} />
              </span>
            </span>
          </button>
          <p className="mt-3 text-sm text-on-surface-variant">
            {playing ? "Воспроизведение" : progress >= 100 ? "Просмотрено" : "Пауза"}
            {minutes ? ` · ${minutes}` : ""}. Ролика в макете нет, поэтому плеер идёт по кадру. Полная запись открывается на YouTube.
          </p>
          <a
            href={youtubeFor(title)}
            target="_blank"
            rel="noreferrer"
            className="mt-3 inline-flex items-center gap-2 font-label-md text-primary"
          >
            Открыть на YouTube
            <Icon name="open_in_new" className="text-[18px]" />
          </a>
        </div>
      )}
    </section>
  );
}
