import { cn } from "@/lib/utils";

export function Icon({
  name,
  fill = false,
  className,
}: {
  name: string;
  fill?: boolean;
  className?: string;
}) {
  return (
    <span
      className={cn("material-symbols-outlined", className)}
      style={{
        fontVariationSettings: `'FILL' ${fill ? 1 : 0}, 'wght' 300, 'GRAD' 0, 'opsz' 24`,
      }}
    >
      {name}
    </span>
  );
}
