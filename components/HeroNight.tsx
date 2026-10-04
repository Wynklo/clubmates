"use client";

import { ArrowRight } from "lucide-react";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import styles from "@/components/HeroNight.module.css";

type Person = {
  name: string;
  skin: string;
  hair: string;
  shirt: string;
};

const maya: Person = { name: "Maya", skin: "#E7B89A", hair: "#2A211C", shirt: "#994EA8" };
const arjun: Person = { name: "Arjun", skin: "#C68642", hair: "#1A1A1A", shirt: "#5C3D32" };
const nia: Person = { name: "Nia", skin: "#8D5524", hair: "#24160F", shirt: "#097270" };
const dev: Person = { name: "Dev", skin: "#E0B090", hair: "#3A2418", shirt: "#484848" };
const sam: Person = { name: "Sam", skin: "#F1C7A6", hair: "#6B3A2A", shirt: "#75457D" };

const nightStack = [maya, arjun, nia, dev, sam];

function Portrait({ person, className }: { person: Person; className?: string }) {
  return (
    <svg viewBox="0 0 64 64" aria-hidden="true" className={className ?? "size-full"}>
      <circle cx="32" cy="32" r="32" fill={person.shirt} />
      <path d="M8 58c4-14 14-20 24-20s20 6 24 20" fill={person.skin} />
      <circle cx="32" cy="26" r="12" fill={person.skin} />
      <path d="M18 24c1-12 8-18 14-18s13 6 14 18c-4-3-8-4-14-4s-10 1-14 4z" fill={person.hair} />
    </svg>
  );
}

function Status({
  person,
  age,
  line,
  className,
}: {
  person: Person;
  age: number;
  line: string;
  className: string;
}) {
  return (
    <div className={`${styles.beat} ${className} text-center`}>
      <span className="mx-auto inline-flex size-10 overflow-hidden rounded-full ring-2 ring-paper shadow-[0_8px_16px_-12px_rgba(28,28,28,0.5)]">
        <Portrait person={person} />
      </span>
      <p className="mt-2 text-sm font-medium text-ink">
        {person.name}, {age}
      </p>
      <p className="mt-0.5 text-xs leading-4 text-stone">{line}</p>
      <p className="mt-2 inline-flex rounded-full bg-[#f3e6f8] px-2.5 py-1 text-[10px] font-medium tracking-wide text-aubergine">
        Club · Dancing · 10 PM
      </p>
    </div>
  );
}

export function HeroNight() {
  const { open } = useEarlyAccess();

  return (
    <aside
      className="relative mx-auto h-[460px] w-full max-w-[440px] lg:h-[500px] lg:max-w-none"
      aria-label="Maya and Arjun both want to go out. They find the same night, agree to go together, meet, and join the people already heading there."
    >
      <div className={`${styles.stage} absolute inset-0`}>
        <div className={`${styles.beat} ${styles.glow}`} />
        <div className={`${styles.beat} ${styles.pulse}`} />

        <div aria-hidden="true">
          <Status person={maya} age={24} line="Wants to go out tonight" className={styles.maya} />
          <Status person={arjun} age={25} line="Heading out tonight" className={styles.arjun} />

          <div className={styles.cluster}>
            <p className={`${styles.beat} ${styles.kicker} text-[11px] font-medium tracking-[0.18em] text-aubergine uppercase`}>
              <span className="mr-1.5">✦</span>
              Same night
            </p>
            <p className={`${styles.beat} ${styles.vibe} mt-2 text-center font-serif text-lg leading-none text-ink`}>
              Club · Tonight · Same vibe
            </p>
            <div
              className={`${styles.beat} ${styles.way} mt-4 w-[252px] rounded-2xl border border-ink/10 bg-paper px-4 py-4 text-center shadow-[0_18px_36px_-28px_rgba(28,28,28,0.45)]`}
            >
              <p className="font-serif text-xl leading-none">Maya + Arjun</p>
              <p className="mt-2 text-sm leading-5 whitespace-nowrap text-stone">You&apos;re heading the same way.</p>
              <p className="mt-2 text-sm text-ink">Club · 10 PM</p>
              <p className="mt-3 text-sm font-semibold text-aubergine">Go together →</p>
            </div>
            <p className={`${styles.beat} ${styles.confirm} ${styles.confirmMaya} mt-3 text-sm text-aubergine`}>
              Maya is in ✓
            </p>
            <p className={`${styles.beat} ${styles.confirm} ${styles.confirmArjun} mt-1 text-sm text-aubergine`}>
              Arjun is in ✓
            </p>
          </div>

          <div
            className={`${styles.beat} ${styles.plan} w-[240px] rounded-2xl border border-ink/10 bg-paper px-5 py-4 text-center shadow-[0_18px_36px_-28px_rgba(28,28,28,0.45)]`}
          >
            <p className="text-[11px] font-medium tracking-[0.18em] text-aubergine uppercase">Tonight</p>
            <div className="mt-3 flex items-center justify-center gap-3">
              <span className="inline-flex size-9 overflow-hidden rounded-full ring-2 ring-paper">
                <Portrait person={maya} />
              </span>
              <span className="text-sm text-aubergine">✦</span>
              <span className="inline-flex size-9 overflow-hidden rounded-full ring-2 ring-paper">
                <Portrait person={arjun} />
              </span>
            </div>
            <p className="mt-3 font-serif text-[1.35rem] leading-none">Maya + Arjun</p>
            <p className="mt-1.5 font-serif text-lg leading-none">Going together</p>
            <p className="mt-3 text-sm text-ink">Club · 10 PM</p>
            <p className="mt-1 text-xs text-stone">Meet at entrance · 9:45 PM</p>
            <p className="mt-3 text-[11px] font-medium tracking-[0.14em] text-aubergine uppercase">
              ✓ Plan confirmed
            </p>
          </div>

          <div className={`${styles.beat} ${styles.meet}`}>
            <div className={`${styles.beat} ${styles.meetRow} text-[11px] font-medium tracking-[0.16em] text-mute uppercase`}>
              <span>Maya</span>
              <span className="size-2 rounded-full bg-ink" />
              <span className="text-sm tracking-normal text-aubergine">✦</span>
              <span className="size-2 rounded-full bg-ink" />
              <span>Arjun</span>
            </div>
            <p className={`${styles.beat} ${styles.meetTime} mt-4 font-serif text-lg leading-none text-ink`}>
              Meet · 9:45 PM
            </p>
            <p className={`${styles.beat} ${styles.meetGo} mt-2 text-sm font-medium text-aubergine`}>
              Going in together →
            </p>
          </div>
        </div>

        <div className={`${styles.beat} ${styles.night}`}>
          <div className="w-full rounded-2xl border border-ink/10 bg-paper px-5 py-4 text-center shadow-[0_18px_36px_-28px_rgba(28,28,28,0.45)]">
            <p className="text-[11px] font-medium tracking-[0.18em] text-aubergine uppercase">Tonight</p>
            <p className="mt-2 font-serif text-[1.45rem] leading-none">Club Night · 10 PM</p>
            <p className="mt-2 text-sm text-stone">Room 48</p>
            <div className="mt-4 flex items-center justify-center gap-2">
              <div className="flex -space-x-2">
                {nightStack.map((person) => (
                  <span
                    key={person.name}
                    className="inline-flex size-7 overflow-hidden rounded-full ring-2 ring-paper"
                  >
                    <Portrait person={person} />
                  </span>
                ))}
              </div>
              <span className="text-xs font-medium text-mute">+9</span>
            </div>
            <p className="mt-2 text-sm text-ink">14 people are in</p>
          </div>
          <p className={`${styles.beat} ${styles.tagline} mt-4 text-center text-sm leading-5 text-stone`}>
            No waiting. No cancelled plans.
            <span className="mt-1 block font-serif text-base text-ink">
              Just go. <span className="text-aubergine">✦</span>
            </span>
          </p>
          <button
            type="button"
            onClick={open}
            className={`${styles.beat} ${styles.join} mt-3 inline-flex items-center gap-1.5 text-sm font-semibold text-aubergine`}
          >
            Join the night
            <ArrowRight className="size-3.5" aria-hidden="true" />
          </button>
        </div>
      </div>
    </aside>
  );
}
