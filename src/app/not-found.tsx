import Link from "next/link";

export default function NotFound() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center px-8 text-center">
      <p className="font-headline-lg tracking-[0.3em]">CULT</p>
      <h1 className="font-headline-md mt-4 mb-2">Страница не найдена</h1>
      <p className="mb-6 text-on-surface-variant">Такого экрана в клинике нет.</p>
      <Link href="/home" className="bg-on-background px-8 py-3 text-white">
        На главную
      </Link>
    </main>
  );
}
