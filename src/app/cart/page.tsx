"use client";

import { useState } from "react";
import Link from "next/link";
import { Chrome } from "@/components/clinic/chrome";
import { useClinic } from "@/components/clinic/providers";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function CartPage() {
  const { cart, setQty, clearCart, profileName, balance, placeOrder, spendBonus } = useClinic();
  const [name, setName] = useState(profileName);
  const [phone, setPhone] = useState("");
  const [method, setMethod] = useState<"clinic" | "courier">("clinic");
  const [address, setAddress] = useState("");
  const [pay, setPay] = useState<"card" | "bonus" | "mixed">("card");
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);
  const total = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const bonusPay = Math.min(balance, pay === "bonus" ? total : Math.round(total * 0.3));
  const due = pay === "card" ? total : total - bonusPay;

  return (
    <Chrome active="shop" fab="none">
      <main className="px-container-margin pt-6">
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Корзина</h1>
        <p className="mb-6 text-on-surface-variant">Состав заказа и оформление. Оплата в этом демо не списывается.</p>
        {done ? (
          <div className="rounded-xl bg-white p-6 text-center luxury-shadow">
            <h2 className="font-headline-sm mb-2">Заказ оформлен</h2>
            <p className="text-on-surface-variant">
              {name}, мы собрали заказ. {method === "clinic" ? "Заберите на ресепшен клиники." : `Курьер приедет по адресу: ${address}.`} К оплате {due.toLocaleString("ru-RU")} ₽.
            </p>
            <Link href="/shop" className="mt-6 inline-block font-label-md text-primary">
              Вернуться в каталог
            </Link>
          </div>
        ) : cart.length === 0 ? (
          <div className="rounded-xl border border-dashed border-outline-variant px-6 py-14 text-center">
            <p className="font-headline-sm mb-2">Корзина пуста</p>
            <p className="mb-4 text-on-surface-variant">Добавьте формулу из каталога косметики.</p>
            <Link href="/shop" className="font-label-md text-primary underline">
              В каталог
            </Link>
          </div>
        ) : (
          <>
            <ul className="mb-6 space-y-4">
              {cart.map((item) => (
                <li key={item.id} className="flex items-center justify-between gap-3 border-b border-outline-variant/40 pb-3">
                  <div>
                    <Link href={`/shop/${item.id}`} className="font-medium">
                      {item.name}
                    </Link>
                    <p className="text-primary">{item.price.toLocaleString("ru-RU")} ₽</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="outline" size="icon-sm" onClick={() => setQty(item.id, item.qty - 1)} aria-label="Меньше">
                      −
                    </Button>
                    <span>{item.qty}</span>
                    <Button variant="outline" size="icon-sm" onClick={() => setQty(item.id, item.qty + 1)} aria-label="Больше">
                      +
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
            <p className="font-headline-sm mb-6">Итого {total.toLocaleString("ru-RU")} ₽</p>
            <form
              className="space-y-4"
              onSubmit={(event) => {
                event.preventDefault();
                if (name.trim().length < 2 || phone.replace(/\D/g, "").length < 11) {
                  setError("Укажите имя и телефон в формате +7.");
                  return;
                }
                if (method === "courier" && address.trim().length < 5) {
                  setError("Для курьера нужен адрес.");
                  return;
                }
                setError("");
                if (pay !== "card" && !spendBonus(bonusPay)) {
                  setError("Бонусов не хватает.");
                  return;
                }
                placeOrder({
                  title: cart.map((item) => item.name).join(", "),
                  total: due,
                  pay: pay === "card" ? "Карта" : pay === "bonus" ? "Бонусы" : "Карта и бонусы",
                });
                clearCart();
                setDone(true);
              }}
            >
              <label className="block text-sm">
                Имя
                <Input value={name} onChange={(event) => setName(event.target.value)} className="mt-1 h-11" />
              </label>
              <label className="block text-sm">
                Телефон
                <Input value={phone} onChange={(event) => setPhone(event.target.value)} placeholder="+7 (___) ___-__-__" className="mt-1 h-11" />
              </label>
              <fieldset className="space-y-2">
                <legend className="mb-1 text-sm">Получение</legend>
                <label className="flex gap-2">
                  <input type="radio" checked={method === "clinic"} onChange={() => setMethod("clinic")} /> В клинике
                </label>
                <label className="flex gap-2">
                  <input type="radio" checked={method === "courier"} onChange={() => setMethod("courier")} /> Курьер
                </label>
              </fieldset>
              {method === "courier" ? (
                <label className="block text-sm">
                  Адрес
                  <Input value={address} onChange={(event) => setAddress(event.target.value)} className="mt-1 h-11" />
                </label>
              ) : null}
              <fieldset className="space-y-2">
                <legend className="mb-1 text-sm">Оплата</legend>
                <label className="flex gap-2">
                  <input type="radio" checked={pay === "card"} onChange={() => setPay("card")} /> Картой при получении
                </label>
                <label className="flex gap-2">
                  <input type="radio" checked={pay === "bonus"} onChange={() => setPay("bonus")} /> Бонусами
                </label>
                <label className="flex gap-2">
                  <input type="radio" checked={pay === "mixed"} onChange={() => setPay("mixed")} /> Смешанная оплата, бонусами до 30%
                </label>
              </fieldset>
              {error ? <p className="text-sm text-error">{error}</p> : null}
              <Button type="submit" className="h-12 w-full bg-on-background text-white tracking-[0.14em] uppercase">
                Оформить заказ
              </Button>
            </form>
          </>
        )}
      </main>
    </Chrome>
  );
}
