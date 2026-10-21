"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Chrome } from "@/components/clinic/chrome";
import { Icon } from "@/components/clinic/icon";
import { contacts } from "@/lib/catalog";
import { useClinic } from "@/components/clinic/providers";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export default function ThreadPage() {
  const params = useParams<{ id: string }>();
  const contact = contacts.find((item) => item.id === params.id);
  const { threads, sendMessage } = useClinic();
  const [text, setText] = useState("");

  if (!contact) {
    return (
      <Chrome active="chat" fab="none">
        <main className="px-container-margin py-10 text-center">
          <p className="mb-4">Диалог не найден.</p>
          <Link href="/chat" className="text-primary underline">
            К центру поддержки
          </Link>
        </main>
      </Chrome>
    );
  }

  const messages = threads[contact.id] ?? [];

  return (
    <Chrome active="chat" fab="none">
      <main className="flex min-h-[70dvh] flex-col px-container-margin pt-4">
        <Link href="/chat" className="mb-4 inline-flex items-center gap-1 text-primary">
          <Icon name="arrow_back" />
          Центр поддержки
        </Link>
        <div className="mb-4 flex items-center gap-3">
          {contact.image ? (
            <img src={contact.image} alt="" className="h-12 w-12 rounded-full object-cover" />
          ) : (
            <span className="flex h-12 w-12 items-center justify-center rounded-full bg-primary-container text-primary">
              <Icon name="smart_toy" />
            </span>
          )}
          <div>
            <h1 className="font-headline-sm">{contact.name}</h1>
            <p className="text-xs tracking-wider text-primary uppercase">{contact.role}</p>
          </div>
        </div>
        <div className="flex-1 space-y-3 pb-4">
          {messages.length === 0 ? (
            <p className="text-center text-on-surface-variant">Сообщений пока нет.</p>
          ) : (
            messages.map((message) => (
              <div
                key={message.id}
                className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-relaxed ${message.from === "me" ? "ml-auto bg-on-background text-white" : "bg-white text-on-surface luxury-shadow"}`}
              >
                {message.text}
              </div>
            ))
          )}
        </div>
        <form
          className="sticky bottom-24 flex gap-2 bg-surface py-2"
          onSubmit={(event) => {
            event.preventDefault();
            sendMessage(contact.id, text);
            setText("");
          }}
        >
          <Input
            value={text}
            onChange={(event) => setText(event.target.value)}
            placeholder="Сообщение"
            aria-label="Сообщение"
            className="h-11"
          />
          <Button type="submit" className="h-11 bg-on-background px-4 text-white">
            Отправить
          </Button>
        </form>
      </main>
    </Chrome>
  );
}
