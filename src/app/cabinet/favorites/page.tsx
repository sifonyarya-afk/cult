"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { products } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";

export default function FavoritesPage() {
  const { favorites, toggleFavorite } = useClinic();
  const list = products.filter((product) => favorites.includes(product.id));
  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <h1 className="font-headline-lg text-headline-lg-mobile mb-4">Избранное</h1>
        {list.length === 0 ? (
          <p className="rounded-xl border border-dashed border-outline-variant px-4 py-12 text-center text-on-surface-variant">
            Отметьте товар сердцем на его странице.
          </p>
        ) : (
          <ul className="space-y-3">
            {list.map((product) => (
              <li key={product.id} className="flex items-center justify-between gap-3 rounded-xl bg-white p-3">
                <Link href={`/shop/${product.id}`} className="flex items-center gap-3">
                  <img src={product.image} alt="" className="h-14 w-14 object-cover" />
                  <span>
                    <span className="block font-medium">{product.name}</span>
                    <span className="text-sm text-primary">{product.priceLabel}</span>
                  </span>
                </Link>
                <button className="text-sm text-error" onClick={() => toggleFavorite(product.id)}>
                  Убрать
                </button>
              </li>
            ))}
          </ul>
        )}
      </main>
    </Chrome>
  );
}
