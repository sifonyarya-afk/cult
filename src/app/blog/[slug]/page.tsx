"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Story } from "@/components/clinic/story";
import { articleBySlug } from "@/lib/catalog";

export default function ArticlePage() {
  const params = useParams<{ slug: string }>();
  const article = articleBySlug(params.slug);

  if (!article) {
    return (
      <Chrome active="home" fab="none">
        <main className="px-container-margin py-12 text-center">
          <p className="mb-3">Материал не найден.</p>
          <Link href="/blog" className="text-primary underline">
            В блог
          </Link>
        </main>
      </Chrome>
    );
  }

  return (
    <Chrome active="home" fab="none">
      <main className="px-container-margin pt-4">
        <Link href="/blog" className="text-sm text-primary">
          Блог
        </Link>
        <p className="mt-4 text-xs tracking-widest text-secondary uppercase">{article.kicker}</p>
        <h1 className="font-headline-md mb-2">{article.title}</h1>
        <p className="mb-5 text-sm text-outline">
          {article.author} · {article.minutes}
        </p>
        <Story title={article.title} image={article.image} minutes={article.minutes} paragraphs={[article.lead, ...article.body]} />
      </main>
    </Chrome>
  );
}
