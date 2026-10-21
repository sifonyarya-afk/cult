"use client";

import { useState } from "react";
import { Chrome } from "@/components/clinic/chrome";
import { devices, services } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const options = [
  ...services.map((item) => item.title),
  ...devices.map((item) => item.title),
  "Консультация",
];

export default function BookingPage() {
  const { sendMessage, profileName } = useClinic();
  const [service, setService] = useState(options[0]);
  const [date, setDate] = useState("");
  const [time, setTime] = useState("10:30");
  const [name, setName] = useState(profileName);
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);

  return (
    <Chrome active="services" fab="none">
      <main className="px-container-margin pt-6">
        <p className="font-label-md mb-2 tracking-[0.2em] text-primary uppercase">Визит</p>
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Запись на услугу</h1>
        <p className="mb-6 text-on-surface-variant">Выберите процедуру, день и время. Подтверждение придёт в чат клиники.</p>
        {done ? (
          <div className="rounded-xl bg-white p-6 luxury-shadow">
            <h2 className="font-headline-sm mb-2">Вы записаны</h2>
            <p className="text-on-surface-variant">
              {name}: {service}, {date} в {time}. Если время занято, администратор предложит соседний слот.
            </p>
          </div>
        ) : (
          <form
            className="space-y-4"
            onSubmit={(event) => {
              event.preventDefault();
              if (!date || name.trim().length < 2) {
                setError("Укажите дату и имя.");
                return;
              }
              setError("");
              sendMessage("admin", `Запись: ${service}, ${date} в ${time}, ${name}.`);
              setDone(true);
            }}
          >
            <label className="block text-sm">
              Услуга
              <select value={service} onChange={(event) => setService(event.target.value)} className="mt-1 h-11 w-full rounded-lg border border-input bg-transparent px-3">
                {options.map((item) => (
                  <option key={item}>{item}</option>
                ))}
              </select>
            </label>
            <label className="block text-sm">
              Дата
              <Input type="date" value={date} onChange={(event) => setDate(event.target.value)} className="mt-1 h-11" />
            </label>
            <label className="block text-sm">
              Время
              <select value={time} onChange={(event) => setTime(event.target.value)} className="mt-1 h-11 w-full rounded-lg border border-input bg-transparent px-3">
                {["09:00", "10:30", "12:00", "15:00", "17:30"].map((item) => (
                  <option key={item}>{item}</option>
                ))}
              </select>
            </label>
            <label className="block text-sm">
              Имя
              <Input value={name} onChange={(event) => setName(event.target.value)} className="mt-1 h-11" />
            </label>
            {error ? <p className="text-sm text-error">{error}</p> : null}
            <Button type="submit" className="h-12 w-full bg-on-background text-white tracking-[0.14em] uppercase">
              Записаться
            </Button>
          </form>
        )}
      </main>
    </Chrome>
  );
}
