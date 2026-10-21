import map from "./media-map.json";

const entries = Object.entries(map as Record<string, string>);

const FALLBACK = entries[0]?.[1] ?? "/media/0de7a9521861.png";

export function img(id: string): string {
  const hit = entries.find(([url]) => url.includes(id));
  return hit?.[1] ?? FALLBACK;
}
