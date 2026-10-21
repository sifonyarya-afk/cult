"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { articles } from "@/lib/catalog";

export default function BlogPage() {
  return (
    <Chrome active="home" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-secondary uppercase">Журнал</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-6">Блог</h1>
        <div className="space-y-6">
          {articles.map((article) => (
            <Link key={article.slug} href={`/blog/${article.slug}`} className="block">
              <img src={article.image} alt="" className="mb-3 aspect-video w-full rounded-xl object-cover" />
              <p className="text-xs tracking-widest text-secondary uppercase">{article.kicker}</p>
              <h2 className="font-headline-sm">{article.title}</h2>
              <p className="text-sm text-on-surface-variant">
                {article.minutes} · {article.author}
              </p>
            </Link>
          ))}
        </div>
      </main>
    </Chrome>
  );
}
