"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { products, type Product } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";

function ProductCard({ product }: { product: Product }) {
  const { addToCart } = useClinic();
  return (
    <article className="mb-12">
      <Link href={`/shop/${product.id}`} className="relative mb-6 block aspect-[4/5] overflow-hidden bg-surface-container-low">
        <img src={product.image} alt={product.name} className="h-full w-full object-cover" />
        {product.badge ? (
          <span className="absolute top-4 right-4 bg-secondary px-3 py-1 text-[10px] font-bold tracking-widest text-white uppercase">
            {product.badge}
          </span>
        ) : (
          <span
            className={`absolute top-4 right-4 flex items-center gap-2 px-3 py-1 text-[10px] font-bold tracking-widest uppercase ${product.stock === "low" ? "bg-error/10 text-error" : "bg-white/90"}`}
          >
            <span className={`h-1.5 w-1.5 rounded-full ${product.stock === "low" ? "bg-error" : "bg-secondary"}`} />
            {product.stock === "low" ? "Мало" : "В наличии"}
          </span>
        )}
        {product.badge ? (
          <span className="absolute top-4 left-4 flex items-center gap-2 bg-white/90 px-3 py-1 text-[10px] font-bold tracking-widest uppercase">
            <span className="h-1.5 w-1.5 rounded-full bg-secondary" />В наличии
          </span>
        ) : null}
      </Link>
      <div className="px-2 text-center">
        <Link href={`/shop/${product.id}`} className="font-headline-sm mb-2 block">
          {product.name}
        </Link>
        <p className="mb-4 text-on-surface-variant italic opacity-70">{product.blurb}</p>
        <p className="font-headline-md mb-6 text-primary">{product.priceLabel}</p>
        <Button
          className="h-auto w-full rounded-none bg-on-background py-4 font-label-md tracking-widest text-white uppercase hover:bg-primary"
          onClick={() => addToCart({ id: product.id, name: product.name, price: product.price })}
        >
          В корзину
        </Button>
      </div>
    </article>
  );
}

export default function ShopPage() {
  const { setInfo, setCartOpen, cart } = useClinic();
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState("supplements");
  const [extra, setExtra] = useState(false);

  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 600);
    return () => window.clearTimeout(timer);
  }, []);

  const visible = products.filter((product) => product.tab === tab).slice(0, extra ? undefined : 4);

  return (
    <Chrome active="shop" fab="calendar">
      <main className="px-container-margin pt-6">
        <div className="mb-8 text-center">
          <h2 className="font-headline-xl text-[40px] leading-tight">Биохакинг-шоп</h2>
          <button
            className="mt-6 flex w-full flex-col items-center gap-2"
            onClick={() =>
              setInfo({
                title: "ИИ Помощник",
                body: "Для сияния кожи начните с Liposomal Gluta-Pure. Для энергии — Cellular Catalyst 01. Откройте чат бота, если нужен разбор состава.",
              })
            }
          >
            <span className="flex h-14 w-14 items-center justify-center rounded-full bg-primary-container text-primary">
              <Icon name="smart_toy" />
            </span>
            <span className="font-label-md tracking-widest text-primary uppercase">ИИ Помощник</span>
          </button>
        </div>
        <Tabs value={tab} onValueChange={setTab}>
          <TabsList variant="line" className="mb-8 h-auto w-full justify-center rounded-none border-b border-outline-variant bg-transparent">
            <TabsTrigger value="cosmetics" className="px-4 py-3 font-label-md tracking-wider uppercase">
              Косметика
            </TabsTrigger>
            <TabsTrigger value="supplements" className="px-4 py-3 font-label-md tracking-wider uppercase">
              БАДы
            </TabsTrigger>
            <TabsTrigger value="store" className="px-4 py-3 font-label-md tracking-wider uppercase">
              Биохакинг-стор
            </TabsTrigger>
          </TabsList>
          {loading ? (
            <div className="space-y-4" aria-busy="true">
              <div className="aspect-[4/5] animate-pulse bg-surface-container-low" />
              <div className="mx-auto h-5 w-1/2 animate-pulse bg-surface-container" />
            </div>
          ) : (
            <>
              <TabsContent value="cosmetics">
                {visible.map((product) => (
                  <ProductCard key={product.id} product={product} />
                ))}
              </TabsContent>
              <TabsContent value="supplements">
                {products
                  .filter((product) => product.tab === "supplements")
                  .map((product) => (
                    <ProductCard key={product.id} product={product} />
                  ))}
              </TabsContent>
              <TabsContent value="store">
                <div className="rounded-xl border border-dashed border-outline-variant px-6 py-16 text-center">
                  <Icon name="inventory_2" className="mb-3 text-outline" />
                  <p className="font-headline-sm mb-2">Биохакинг-стор пуст</p>
                  <p className="text-on-surface-variant">Устройства и наборы появятся в следующем поступлении. Пока смотрите БАДы.</p>
                  <button className="mt-6 font-label-md text-primary underline" onClick={() => setTab("supplements")}>
                    К БАДам
                  </button>
                </div>
              </TabsContent>
            </>
          )}
        </Tabs>
        <div className="flex justify-center py-8">
          <button className="flex items-center gap-3 font-label-md tracking-[0.2em] uppercase" onClick={() => setExtra(true)}>
            Узнать больше
            <Icon name="east" />
          </button>
        </div>
        {cart.length > 0 ? (
          <button className="mb-4 w-full text-center text-sm text-primary underline" onClick={() => setCartOpen(true)}>
            Открыть корзину ({cart.reduce((sum, item) => sum + item.qty, 0)})
          </button>
        ) : null}
      </main>
    </Chrome>
  );
}
