"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useClinic } from "./providers";
import { Icon } from "./icon";
import { mediaIds } from "@/lib/catalog";
import { cn } from "@/lib/utils";

type NavId = "home" | "services" | "shop" | "chat" | "profile" | "science" | "health" | "gallery";
type NavMode = "standard" | "science" | "english" | "device" | "thorne" | "pill";
type FabMode = "add" | "calendar" | "event" | "book" | "dual" | "none";
type Brand = "wordmark" | "logo" | "infusion" | "thorne";

const items: Record<
  NavMode,
  { href: string; id: NavId; icon: string; label: string }[]
> = {
  standard: [
    { href: "/home", id: "home", icon: "home", label: "Главная" },
    { href: "/services", id: "services", icon: "medical_services", label: "Услуги" },
    { href: "/shop", id: "shop", icon: "shopping_bag", label: "Магазин" },
    { href: "/chat", id: "chat", icon: "chat_bubble", label: "Чат" },
    { href: "/cabinet", id: "profile", icon: "person", label: "Профиль" },
  ],
  pill: [
    { href: "/home", id: "home", icon: "home", label: "Главная" },
    { href: "/services", id: "services", icon: "spa", label: "Услуги" },
    { href: "/shop", id: "shop", icon: "shopping_bag", label: "Магазин" },
    { href: "/chat", id: "chat", icon: "chat_bubble", label: "Чат" },
    { href: "/cabinet", id: "profile", icon: "person", label: "Профиль" },
  ],
  science: [
    { href: "/home", id: "home", icon: "home", label: "Главная" },
    { href: "/services", id: "services", icon: "spa", label: "Услуги" },
    { href: "/science", id: "science", icon: "science", label: "Наука" },
    { href: "/shop", id: "shop", icon: "shopping_bag", label: "Магазин" },
    { href: "/chat", id: "chat", icon: "chat", label: "Чат" },
    { href: "/cabinet", id: "profile", icon: "person", label: "Профиль" },
  ],
  english: [
    { href: "/home", id: "home", icon: "home", label: "Home" },
    { href: "/services", id: "services", icon: "spa", label: "Services" },
    { href: "/shop", id: "shop", icon: "shopping_bag", label: "Shop" },
    { href: "/chat", id: "chat", icon: "chat_bubble", label: "Chat" },
    { href: "/cabinet", id: "profile", icon: "person", label: "Profile" },
  ],
  device: [
    { href: "/home", id: "home", icon: "home", label: "Home" },
    { href: "/services", id: "services", icon: "spa", label: "Services" },
    { href: "/shop", id: "shop", icon: "shopping_bag", label: "Shop" },
    { href: "/chat", id: "chat", icon: "chat_bubble", label: "Chat" },
    { href: "/science", id: "gallery", icon: "auto_awesome", label: "Gallery" },
    { href: "/cabinet", id: "profile", icon: "person", label: "Profile" },
  ],
  thorne: [
    { href: "/home", id: "home", icon: "home", label: "Главная" },
    { href: "/shop", id: "shop", icon: "shopping_bag", label: "Магазин" },
    { href: "/science", id: "health", icon: "medical_services", label: "Здоровье" },
    { href: "/cabinet", id: "profile", icon: "person", label: "Профиль" },
  ],
};

export function Chrome({
  children,
  active,
  nav = "standard",
  fab = "add",
  brand = "wordmark",
  header = true,
  bookBar,
  servicesIcon,
}: {
  children: React.ReactNode;
  active: NavId;
  nav?: NavMode;
  fab?: FabMode;
  brand?: Brand;
  header?: boolean;
  bookBar?: { label: string; title: string };
  servicesIcon?: string;
}) {
  const clinic = useClinic();
  const router = useRouter();
  const fabStyle = { bottom: 112, right: "max(24px, calc(50% - 176px))" } as const;
  const links = items[nav].map((item) =>
    item.id === "services" && servicesIcon ? { ...item, icon: servicesIcon } : item,
  );
  const rounded = nav === "english" || nav === "pill" || nav === "device";
  const count = clinic.cart.reduce((sum, item) => sum + item.qty, 0);

  return (
    <div className={cn("min-h-dvh", header ? "pt-16" : "", bookBar ? "pb-44" : "pb-24")}>
      {header ? (
        <header className="dock top-0 flex h-16 items-center justify-between bg-surface/90 px-container-margin backdrop-blur-md">
          <button aria-label="Меню" className="text-primary" onClick={() => clinic.setMenuOpen(true)}>
            <Icon name="menu" />
          </button>
          {brand === "logo" ? (
            <img src={mediaIds.logo} alt="CULT Clinic" className="h-8 object-contain" />
          ) : brand === "infusion" ? (
            <img src={mediaIds.infusionLogo} alt="CULT" className="h-6 object-contain" />
          ) : brand === "thorne" ? (
            <img src={mediaIds.thorneLogo} alt="CULT" className="h-6 object-contain" />
          ) : (
            <Link href="/home" className="font-headline-lg text-[28px] tracking-[0.28em] text-on-surface">
              CULT
            </Link>
          )}
          {nav === "science" ? (
            <Link href="/cabinet" aria-label="Профиль" className="text-primary">
              <Icon name="account_circle" />
            </Link>
          ) : (
            <button aria-label="Уведомления" className="text-primary" onClick={() => clinic.setNotesOpen(true)}>
              <Icon name="notifications" />
            </button>
          )}
        </header>
      ) : null}

      {children}

      {bookBar ? (
        <div className="dock bottom-20 border-t border-outline-variant/30 bg-surface px-container-margin py-3">
          <button
            className="h-14 w-full bg-on-background font-label-md text-label-md tracking-[0.2em] text-white uppercase"
            onClick={() => clinic.openBooking(bookBar.title)}
          >
            {bookBar.label}
          </button>
        </div>
      ) : null}

      <nav
        className={cn(
          "dock bottom-0 flex h-20 items-center justify-around border-t border-outline-variant bg-surface px-2",
          rounded && "rounded-t-full border-t-0 shadow-[0_-10px_40px_rgba(110,91,67,0.05)]",
        )}
      >
        {links.map((item) => {
          const on = item.id === active;
          return (
            <Link
              key={item.href + item.label}
              href={item.href}
              className={cn(
                "flex flex-col items-center justify-center text-[11px] text-on-surface-variant",
                on && "scale-110 font-bold text-secondary",
                on && rounded && "rounded-full bg-secondary-container/30 px-3 py-1 text-primary",
              )}
            >
              <Icon name={item.icon} fill={on} className="text-[22px]" />
              <span className={cn("font-label-md", nav === "science" ? "text-[10px]" : "text-[11px]", nav === "pill" && "uppercase")}>
                {item.label}
              </span>
              {item.id === "shop" && count > 0 ? (
                <span className="sr-only">{count} в корзине</span>
              ) : null}
            </Link>
          );
        })}
      </nav>

      {fab === "add" || fab === "calendar" || fab === "event" ? (
        <button
          aria-label="Запись"
          className="fixed z-40 flex h-14 w-14 items-center justify-center rounded-full bg-on-background text-white shadow-xl"
          style={fabStyle}
          onClick={() => clinic.openBooking()}
        >
          <Icon name={fab === "add" ? "add" : fab === "event" ? "event" : "calendar_month"} />
        </button>
      ) : null}
      {fab === "book" ? (
        <button
          className="fixed z-40 flex items-center gap-2 rounded-full bg-primary px-6 py-3 font-label-md text-white shadow-xl"
          style={{ bottom: 104, right: "max(24px, calc(50% - 176px))" }}
          onClick={() => clinic.openBooking("Инъекционная косметология")}
        >
          Записаться
          <Icon name="calendar_month" />
        </button>
      ) : null}
      {fab === "dual" ? (
        <>
          <button
            aria-label="ИИ-помощник"
            className="fixed z-40 flex h-14 w-14 items-center justify-center rounded-full border border-primary/20 bg-white text-primary shadow-xl"
            style={{ bottom: 176, right: "max(24px, calc(50% - 176px))" }}
            onClick={() => router.push("/chat/bot")}
          >
            <Icon name="smart_toy" />
          </button>
          <button
            aria-label="Запись"
            className="fixed z-40 flex h-14 w-14 items-center justify-center rounded-full bg-on-background text-white shadow-xl"
            style={{ bottom: 108, right: "max(24px, calc(50% - 176px))" }}
            onClick={() => clinic.openBooking("Аппаратная косметология")}
          >
            <Icon name="calendar_month" />
          </button>
        </>
      ) : null}
    </div>
  );
}
