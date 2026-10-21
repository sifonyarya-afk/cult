"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { articles, YOUTUBE_CHANNEL } from "@/lib/catalog";

export default function TvPage() {
  const videos = articles.filter((item) => item.kind === "video");
  return (
    <Chrome active="home" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-secondary uppercase">CULT TV</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-3">Канал клиники</h1>
        <p className="mb-5 text-on-surface-variant">Смотрите разборы здесь или перейдите на YouTube. У канала в макете нет своей ссылки, поэтому открывается поиск CULT Clinic.</p>
        <a href={YOUTUBE_CHANNEL} target="_blank" rel="noreferrer" className="mb-8 flex items-center justify-center gap-2 bg-on-background py-4 font-label-md tracking-widest text-white uppercase">
          Перейти на YouTube
          <Icon name="open_in_new" />
        </a>
        <div className="space-y-5">
          {videos.map((video) => (
            <Link key={video.slug} href={`/blog/${video.slug}`} className="block">
              <span className="relative mb-2 block aspect-video overflow-hidden rounded-xl">
                <img src={video.image} alt="" className="h-full w-full object-cover" />
                <span className="absolute inset-0 flex items-center justify-center">
                  <span className="flex h-12 w-12 items-center justify-center rounded-full bg-white/80">
                    <Icon name="play_arrow" fill />
                  </span>
                </span>
              </span>
              <span className="font-medium">{video.title}</span>
              <span className="block text-sm text-on-surface-variant">
                {video.minutes} · {video.author}
              </span>
            </Link>
          ))}
        </div>
      </main>
    </Chrome>
  );
}
