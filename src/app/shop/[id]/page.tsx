"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Story } from "@/components/clinic/story";
import { productNotes, products } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Button } from "@/components/ui/button";

export default function ProductPage() {
  const params = useParams<{ id: string }>();
  const product = products.find((item) => item.id === params.id);
  const { addToCart } = useClinic();

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

  return (
    <Chrome active="shop" fab="none">
      <main className="px-container-margin pt-4">
        <Link href="/shop" className="mb-3 inline-block text-sm text-primary">
          Каталог косметики
        </Link>
        <img src={product.image} alt={product.name} className="mb-5 aspect-[4/5] w-full object-cover" />
        <p className="font-label-md tracking-widest text-primary uppercase">
          {product.tab === "cosmetics" ? "Косметика" : "БАДы"} · {product.stock === "low" ? "Мало" : "В наличии"}
        </p>
        <h1 className="font-headline-md mt-1">{product.name}</h1>
        <p className="mt-2 italic text-on-surface-variant">{product.blurb}</p>
        <p className="font-headline-md my-4 text-primary">{product.priceLabel}</p>
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
