"use client";

import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { useClinic } from "@/components/clinic/providers";

export default function OrdersPage() {
  const { orders } = useClinic();
  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <h1 className="font-headline-lg text-headline-lg-mobile mb-4">Мои заказы</h1>
        {orders.length === 0 ? (
          <div className="rounded-xl border border-dashed border-outline-variant px-4 py-12 text-center">
            <p className="mb-2">Покупок пока нет.</p>
            <Link href="/shop" className="text-primary underline">
              В каталог
            </Link>
          </div>
        ) : (
          <ul className="space-y-3">
            {orders.map((order) => (
              <li key={order.id} className="rounded-xl bg-white p-4 luxury-shadow">
                <p className="text-xs text-outline">{order.at}</p>
                <p className="font-medium">{order.title}</p>
                <p className="text-sm text-on-surface-variant">{order.pay}</p>
                <p className="font-headline-sm text-primary">{order.total.toLocaleString("ru-RU")} ₽</p>
              </li>
            ))}
          </ul>
        )}
      </main>
    </Chrome>
  );
}
