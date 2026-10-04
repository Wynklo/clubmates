import type { Person } from "@/components/people";

export function Avatar({ person, className = "size-full" }: { person: Person; className?: string }) {
  return (
    <svg viewBox="0 0 64 64" aria-hidden="true" className={className}>
      <circle cx="32" cy="32" r="32" fill={person.shirt} />
      <path d="M8 58c4-14 14-20 24-20s20 6 24 20" fill={person.skin} />
      <circle cx="32" cy="26" r="12" fill={person.skin} />
      <path d="M18 24c1-12 8-18 14-18s13 6 14 18c-4-3-8-4-14-4s-10 1-14 4z" fill={person.hair} />
    </svg>
  );
}

export function AvatarFace({
  person,
  className = "size-10",
  ring = "ring-paper",
}: {
  person: Person;
  className?: string;
  ring?: string;
}) {
  return (
    <span className={`avatar-hover inline-flex overflow-hidden rounded-full ring-2 ${ring} ${className}`}>
      <Avatar person={person} />
    </span>
  );
}

export function AvatarStack({
  people,
  className = "",
  face = "size-8",
  ring = "ring-paper",
}: {
  people: Person[];
  className?: string;
  face?: string;
  ring?: string;
}) {
  return (
    <div className={`flex -space-x-2 ${className}`}>
      {people.map((person) => (
        <AvatarFace key={person.name} person={person} className={face} ring={ring} />
      ))}
    </div>
  );
}
