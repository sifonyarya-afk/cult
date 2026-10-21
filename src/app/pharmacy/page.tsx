"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { pharmacy, products } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Button } from "@/components/ui/button";

export default function PharmacyPage() {
  const { addToCart } = useClinic();
  const rows = pharmacy
    .map((item) => ({ ...item, product: products.find((product) => product.id === item.productId) }))
    .filter((item) => item.product);

  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Кабинет</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Личная аптека</h1>
        <p className="mb-6 text-on-surface-variant">Назначения врачей. Повторить заказ можно сразу в корзину.</p>
        {rows.length === 0 ? (
          <p className="rounded-xl border border-dashed border-outline-variant px-4 py-10 text-center">Назначений пока нет.</p>
        ) : (
          <ul className="space-y-4">
            {rows.map((row) => (
              <li key={row.productId} className="rounded-xl bg-white p-4 luxury-shadow">
                <Link href={`/shop/${row.product!.id}`} className="flex gap-3">
                  <img src={row.product!.image} alt="" className="h-16 w-16 object-cover" />
                  <span>
                    <span className="font-medium">{row.product!.name}</span>
                    <span className="block text-sm text-on-surface-variant">{row.dose}</span>
                    <span className="block text-xs text-outline">
                      {row.doctor} · {row.until}
                    </span>
                  </span>
                </Link>
                <Button
                  className="mt-3 h-10 w-full bg-on-background text-white"
                  onClick={() => addToCart({ id: row.product!.id, name: row.product!.name, price: row.product!.price })}
                >
                  В корзину
                </Button>
              </li>
            ))}
          </ul>
        )}
        <Link href="/chat/specialist" className="mt-6 block text-center font-label-md text-primary">
          Спросить врача о схеме
        </Link>
      </main>
    </Chrome>
  );
}
