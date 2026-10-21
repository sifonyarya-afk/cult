"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Story } from "@/components/clinic/story";
import { Icon } from "@/components/clinic/icon";
import { composition, productNotes, products } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Button } from "@/components/ui/button";

export default function ProductPage() {
  const params = useParams<{ id: string }>();
  const product = products.find((item) => item.id === params.id);
  const { addToCart, favorites, toggleFavorite } = useClinic();

  if (!product) {
    return (
      <Chrome active="shop" fab="none">
        <main className="px-container-margin py-12 text-center">
          <p className="mb-3">Товар не найден.</p>
          <Link href="/shop" className="text-primary underline">
            В каталог
          </Link>
        </main>
      </Chrome>
    );
  }

  const note = productNotes[product.id];
  const formula = composition[product.id];
  const liked = favorites.includes(product.id);
  const kind = product.tab === "cosmetics" ? "Косметика" : product.tab === "biohack" ? "Биохакинг" : "БАДы";

  return (
    <Chrome active="shop" fab="none">
      <main className="px-container-margin pt-4">
        <Link href="/shop" className="mb-3 inline-block text-sm text-primary">
          Каталог косметики
        </Link>
        <img src={product.image} alt={product.name} className="mb-5 aspect-[4/5] w-full object-cover" />
        <div className="flex items-start justify-between gap-3">
          <p className="font-label-md tracking-widest text-primary uppercase">
            {kind} · {product.stock === "low" ? "Мало" : "В наличии"}
          </p>
          <button
            aria-label={liked ? "Убрать из избранного" : "В избранное"}
            className="text-primary"
            onClick={() => toggleFavorite(product.id)}
          >
            <Icon name={liked ? "favorite" : "favorite_border"} />
          </button>
        </div>
        <h1 className="font-headline-md mt-1">{product.name}</h1>
        <p className="mt-2 italic text-on-surface-variant">{product.blurb}</p>
        <p className="font-headline-md my-4 text-primary">{product.priceLabel}</p>
        {formula ? (
          <p className="mb-4 text-sm text-on-surface-variant">
            <span className="font-medium text-on-surface">Состав. </span>
            {formula}
          </p>
        ) : null}
        <Button
          className="mb-8 h-12 w-full bg-on-background text-white tracking-[0.16em] uppercase"
          onClick={() => addToCart({ id: product.id, name: product.name, price: product.price })}
        >
          В корзину
        </Button>
        {note ? (
          <Story title={product.name} image={product.image} paragraphs={[note.about, ...note.use]} />
        ) : null}
        <Link href="/cart" className="mt-8 block text-center font-label-md text-primary">
          Перейти к оформлению
        </Link>
      </main>
    </Chrome>
  );
}
