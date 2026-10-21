"use client";

import { Chrome } from "@/components/clinic/chrome";
import { useClinic } from "@/components/clinic/providers";

const rows = [
  ["visits", "Запись и отмена визита"],
  ["analyses", "Готовность анализов"],
  ["pharmacy", "Новые назначения врача"],
  ["offers", "Акции и спецпредложения"],
] as const;

export default function SettingsPage() {
  const { notices, setNotice } = useClinic();
  return (
    <Chrome active="profile" fab="none">
      <main className="px-container-margin pt-6">
        <h1 className="font-headline-lg text-headline-lg-mobile mb-2">Уведомления</h1>
        <p className="mb-6 text-on-surface-variant">Пуши о визите, анализах, аптечке и акциях. В этом демо они остаются на устройстве.</p>
        <ul className="divide-y divide-outline-variant/40 rounded-xl bg-white">
          {rows.map(([key, label]) => (
            <li key={key} className="flex items-center justify-between gap-3 px-4 py-4">
              <span>{label}</span>
              <button
                className={`rounded-full px-4 py-1 text-sm ${notices[key] ? "bg-on-background text-white" : "bg-surface-container"}`}
                onClick={() => setNotice(key, !notices[key])}
              >
                {notices[key] ? "Вкл" : "Выкл"}
              </button>
            </li>
          ))}
        </ul>
      </main>
    </Chrome>
  );
}
