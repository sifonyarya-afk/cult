"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { contacts } from "@/lib/catalog";
import { Icon } from "./icon";

export type CartItem = { id: string; name: string; price: number; qty: number };
export type ChatMessage = { id: string; from: "me" | "them"; text: string };

type Threads = Record<string, ChatMessage[]>;

type ClinicContextValue = {
  ready: boolean;
  cart: CartItem[];
  addToCart: (item: { id: string; name: string; price: number }) => void;
  setQty: (id: string, qty: number) => void;
  cartOpen: boolean;
  setCartOpen: (open: boolean) => void;
  menuOpen: boolean;
  setMenuOpen: (open: boolean) => void;
  openBooking: (title?: string) => void;
  notesOpen: boolean;
  setNotesOpen: (open: boolean) => void;
  threads: Threads;
  sendMessage: (contactId: string, text: string) => void;
  profileName: string;
  setProfileName: (name: string) => void;
  gender: "m" | "f" | null;
  setGender: (gender: "m" | "f") => void;
  bonusClaimed: boolean;
  claimBonus: () => void;
  balance: number;
  playTitle: string | null;
  setPlayTitle: (title: string | null) => void;
  info: { title: string; body: string } | null;
  setInfo: (info: { title: string; body: string } | null) => void;
};

const ClinicContext = createContext<ClinicContextValue | null>(null);

const seedThreads = (): Threads =>
  Object.fromEntries(
    contacts.map((contact) => [
      contact.id,
      [{ id: `${contact.id}-seed`, from: "them" as const, text: contact.seed }],
    ]),
  );

const menuLinks = [
  { href: "/home", label: "Главная" },
  { href: "/services", label: "Услуги" },
  { href: "/specialists", label: "AlethiaPro" },
  { href: "/doctors/thorne", label: "Д-р Элара Торн" },
  { href: "/hardware", label: "Аппаратная косметология" },
  { href: "/injection", label: "Инъекционная" },
  { href: "/infusion", label: "Инфузии" },
  { href: "/science", label: "Наука" },
  { href: "/shop", label: "Магазин" },
  { href: "/chat", label: "Чат" },
  { href: "/cabinet", label: "Личный кабинет" },
];

export function Providers({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [cartOpen, setCartOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [bookingOpen, setBookingOpen] = useState(false);
  const [bookingTitle, setBookingTitle] = useState("Онлайн запись");
  const [bookingDone, setBookingDone] = useState(false);
  const [bookingDate, setBookingDate] = useState("");
  const [bookingTime, setBookingTime] = useState("10:30");
  const [bookingError, setBookingError] = useState("");
  const [notesOpen, setNotesOpen] = useState(false);
  const [threads, setThreads] = useState<Threads>(seedThreads);
  const [profileName, setProfileName] = useState("Александра В.");
  const [gender, setGenderState] = useState<"m" | "f" | null>(null);
  const [bonusClaimed, setBonusClaimed] = useState(false);
  const [checkoutDone, setCheckoutDone] = useState(false);
  const [playTitle, setPlayTitle] = useState<string | null>(null);
  const [info, setInfo] = useState<{ title: string; body: string } | null>(null);

  useEffect(() => {
    try {
      const storedCart = localStorage.getItem("cult-cart");
      const storedThreads = localStorage.getItem("cult-chat");
      const storedName = localStorage.getItem("cult-name");
      const storedGender = localStorage.getItem("cult-gender");
      const storedBonus = localStorage.getItem("cult-bonus");
      if (storedCart) setCart(JSON.parse(storedCart));
      if (storedThreads) setThreads(JSON.parse(storedThreads));
      if (storedName) setProfileName(storedName);
      if (storedGender === "m" || storedGender === "f") setGenderState(storedGender);
      if (storedBonus === "1") setBonusClaimed(true);
    } catch {
      /* ignore broken local data */
    }
    setReady(true);
  }, []);

  useEffect(() => {
    if (!ready) return;
    localStorage.setItem("cult-cart", JSON.stringify(cart));
  }, [cart, ready]);

  useEffect(() => {
    if (!ready) return;
    localStorage.setItem("cult-chat", JSON.stringify(threads));
  }, [threads, ready]);

  const addToCart = useCallback((item: { id: string; name: string; price: number }) => {
    setCart((current) => {
      const found = current.find((entry) => entry.id === item.id);
      if (found) {
        return current.map((entry) =>
          entry.id === item.id ? { ...entry, qty: entry.qty + 1 } : entry,
        );
      }
      return [...current, { ...item, qty: 1 }];
    });
    setCartOpen(true);
  }, []);

  const setQty = useCallback((id: string, qty: number) => {
    setCart((current) =>
      qty <= 0 ? current.filter((entry) => entry.id !== id) : current.map((entry) => (entry.id === id ? { ...entry, qty } : entry)),
    );
  }, []);

  const openBooking = useCallback((title?: string) => {
    setBookingTitle(title || "Онлайн запись");
    setBookingDone(false);
    setBookingError("");
    setBookingOpen(true);
  }, []);

  const sendMessage = useCallback((contactId: string, text: string) => {
    const clean = text.trim();
    if (!clean) return;
    const mine: ChatMessage = { id: `${Date.now()}`, from: "me", text: clean };
    setThreads((current) => ({
      ...current,
      [contactId]: [...(current[contactId] ?? []), mine],
    }));
    const reply =
      contactId === "bot"
        ? "Записала вопрос. Могу открыть услуги, магазин или запись — напишите, что нужно."
        : "Спасибо, сообщение получили. Ответим в этом чате в рабочие часы клиники.";
    window.setTimeout(() => {
      setThreads((current) => ({
        ...current,
        [contactId]: [
          ...(current[contactId] ?? []),
          { id: `${Date.now()}-r`, from: "them", text: reply },
        ],
      }));
    }, 700);
  }, []);

  const setGender = useCallback((value: "m" | "f") => {
    setGenderState(value);
    localStorage.setItem("cult-gender", value);
  }, []);

  const claimBonus = useCallback(() => {
    setBonusClaimed(true);
    localStorage.setItem("cult-bonus", "1");
  }, []);

  const updateName = useCallback((name: string) => {
    setProfileName(name);
    localStorage.setItem("cult-name", name);
  }, []);

  const total = cart.reduce((sum, item) => sum + item.price * item.qty, 0);
  const balance = 12450 + (bonusClaimed ? 3000 : 0);

  const value = useMemo<ClinicContextValue>(
    () => ({
      ready,
      cart,
      addToCart,
      setQty,
      cartOpen,
      setCartOpen,
      menuOpen,
      setMenuOpen,
      openBooking,
      notesOpen,
      setNotesOpen,
      threads,
      sendMessage,
      profileName,
      setProfileName: updateName,
      gender,
      setGender,
      bonusClaimed,
      claimBonus,
      balance,
      playTitle,
      setPlayTitle,
      info,
      setInfo,
    }),
    [
      ready,
      cart,
      addToCart,
      setQty,
      cartOpen,
      menuOpen,
      openBooking,
      notesOpen,
      threads,
      sendMessage,
      profileName,
      updateName,
      gender,
      setGender,
      bonusClaimed,
      claimBonus,
      balance,
      playTitle,
      info,
    ],
  );

  return (
    <ClinicContext.Provider value={value}>
      {children}
      <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
        <SheetContent side="left" className="bg-surface px-0">
          <SheetHeader>
            <SheetTitle className="font-headline-md px-2 tracking-[0.3em]">CULT</SheetTitle>
          </SheetHeader>
          <nav className="flex flex-col">
            {menuLinks.map((link) => (
              <button
                key={link.href}
                className="px-6 py-3 text-left font-body-md text-on-surface hover:bg-surface-container-low"
                onClick={() => {
                  setMenuOpen(false);
                  router.push(link.href);
                }}
              >
                {link.label}
              </button>
            ))}
          </nav>
        </SheetContent>
      </Sheet>

      <Sheet open={cartOpen} onOpenChange={setCartOpen}>
        <SheetContent side="bottom" className="max-h-[80dvh] rounded-t-2xl bg-surface">
          <SheetHeader>
            <SheetTitle className="font-headline-sm">Корзина</SheetTitle>
          </SheetHeader>
          {cart.length === 0 ? (
            <p className="px-4 pb-6 text-on-surface-variant">Корзина пуста. Добавьте формулу из биохакинг-шопа.</p>
          ) : (
            <div className="space-y-3 overflow-y-auto px-4 pb-4">
              {cart.map((item) => (
                <div key={item.id} className="flex items-center justify-between gap-3 border-b border-outline-variant/40 pb-3">
                  <div>
                    <p className="font-medium">{item.name}</p>
                    <p className="text-primary">{item.price.toLocaleString("ru-RU")} ₽</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="outline" size="icon-sm" onClick={() => setQty(item.id, item.qty - 1)} aria-label="Меньше">
                      −
                    </Button>
                    <span className="w-5 text-center">{item.qty}</span>
                    <Button variant="outline" size="icon-sm" onClick={() => setQty(item.id, item.qty + 1)} aria-label="Больше">
                      +
                    </Button>
                  </div>
                </div>
              ))}
              <div className="flex items-center justify-between pt-2 font-headline-sm">
                <span>Итого</span>
                <span>{total.toLocaleString("ru-RU")} ₽</span>
              </div>
              <Button
                className="h-12 w-full bg-on-background text-white tracking-[0.2em] uppercase"
                onClick={() => {
                  setCart([]);
                  setCartOpen(false);
                  setCheckoutDone(true);
                }}
              >
                Оформить
              </Button>
            </div>
          )}
        </SheetContent>
      </Sheet>

      <Dialog open={bookingOpen} onOpenChange={setBookingOpen}>
        <DialogContent className="bg-surface">
          <DialogHeader>
            <DialogTitle className="font-headline-sm">{bookingDone ? "Запись принята" : bookingTitle}</DialogTitle>
            <DialogDescription>
              {bookingDone
                ? "Мы подтвердим визит сообщением в чат администратора."
                : "Выберите день и время. Это учебная запись, без оплаты."}
            </DialogDescription>
          </DialogHeader>
          {bookingDone ? (
            <Button className="h-11 bg-on-background text-white" onClick={() => setBookingOpen(false)}>
              Хорошо
            </Button>
          ) : (
            <form
              className="space-y-3"
              onSubmit={(event) => {
                event.preventDefault();
                if (!bookingDate) {
                  setBookingError("Укажите дату визита.");
                  return;
                }
                setBookingError("");
                setBookingDone(true);
                const contact = "admin";
                setThreads((current) => ({
                  ...current,
                  [contact]: [
                    ...(current[contact] ?? []),
                    {
                      id: `${Date.now()}-book`,
                      from: "them",
                      text: `Заявка: ${bookingTitle}, ${bookingDate} в ${bookingTime}. Подтвердим в ближайшее время.`,
                    },
                  ],
                }));
              }}
            >
              <label className="block text-sm text-outline">
                Дата
                <Input type="date" value={bookingDate} onChange={(event) => setBookingDate(event.target.value)} className="mt-1 h-11" />
              </label>
              <label className="block text-sm text-outline">
                Время
                <select
                  value={bookingTime}
                  onChange={(event) => setBookingTime(event.target.value)}
                  className="mt-1 h-11 w-full rounded-lg border border-input bg-transparent px-3"
                >
                  {["09:00", "10:30", "12:00", "15:00", "17:30"].map((time) => (
                    <option key={time}>{time}</option>
                  ))}
                </select>
              </label>
              {bookingError ? <p className="text-sm text-error">{bookingError}</p> : null}
              <Button type="submit" className="h-11 w-full bg-on-background text-white tracking-[0.18em] uppercase">
                Записаться
              </Button>
            </form>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={notesOpen} onOpenChange={setNotesOpen}>
        <DialogContent className="bg-surface">
          <DialogHeader>
            <DialogTitle className="font-headline-sm">Уведомления</DialogTitle>
            <DialogDescription>Новых уведомлений нет. Напомним о визите за день.</DialogDescription>
          </DialogHeader>
        </DialogContent>
      </Dialog>

      <Dialog open={checkoutDone} onOpenChange={setCheckoutDone}>
        <DialogContent className="bg-surface">
          <DialogHeader>
            <DialogTitle className="font-headline-sm">Заказ принят</DialogTitle>
            <DialogDescription>Формулы зарезервированы. Оплата в клинике или при выдаче.</DialogDescription>
          </DialogHeader>
          <Button className="h-11 bg-on-background text-white" onClick={() => setCheckoutDone(false)}>
            Закрыть
          </Button>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(playTitle)} onOpenChange={(open) => !open && setPlayTitle(null)}>
        <DialogContent className="bg-surface">
          <DialogHeader>
            <DialogTitle className="font-headline-sm">{playTitle}</DialogTitle>
            <DialogDescription>
              В макете нет файла видео. Здесь короткий титр канала CULT TV, затем можно вернуться к экрану.
            </DialogDescription>
          </DialogHeader>
          <div className="flex h-36 items-center justify-center rounded-xl bg-on-background text-white">
            <Icon name="play_arrow" fill className="text-4xl" />
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(info)} onOpenChange={(open) => !open && setInfo(null)}>
        <DialogContent className="bg-surface">
          <DialogHeader>
            <DialogTitle className="font-headline-sm">{info?.title}</DialogTitle>
            <DialogDescription>{info?.body}</DialogDescription>
          </DialogHeader>
        </DialogContent>
      </Dialog>
    </ClinicContext.Provider>
  );
}

export function useClinic() {
  const value = useContext(ClinicContext);
  if (!value) throw new Error("useClinic outside provider");
  return value;
}
