import { AvatarFace } from "@/components/Avatar";
import { arjun, maya, sam, type Person } from "@/components/people";
import styles from "./GapChat.module.css";

const bubble =
  "max-w-[15rem] rounded-2xl border border-paper/10 bg-paper/[0.04] px-3 py-2 text-sm leading-5 text-paper";

function ChatLine({
  person,
  name,
  text,
  beat,
}: {
  person: Person;
  name: string;
  text: string;
  beat: string;
}) {
  return (
    <div className={`${styles.beat} ${beat} flex items-end gap-2`}>
      <AvatarFace person={person} className="size-6 shrink-0" ring="ring-ink" />
      <div>
        <p className="mb-1 text-[11px] text-paper/55">{name}</p>
        <p className={bubble}>{text}</p>
      </div>
    </div>
  );
}

export function GapChat() {
  return (
    <div className="mx-auto w-full max-w-sm" aria-hidden="true">
      <p className={`${styles.beat} ${styles.clock} text-[11px] font-medium tracking-[0.16em] text-paper/45 uppercase`}>
        Friday · 8:42 PM
      </p>
      <div className="mt-5 space-y-3">
        <ChatLine person={maya} name="Maya" text="Anyone going out tonight?" beat={styles.maya} />
        <ChatLine person={sam} name="Sam" text="can't tonight 😭" beat={styles.sam} />
        <ChatLine person={arjun} name="Arjun" text="maybe, not sure yet" beat={styles.arjun} />
        <div className={`${styles.beat} ${styles.reply}`}>
          <p className="mb-1 ml-8 text-[11px] text-paper/55">Maya</p>
          <p className={`${bubble} ml-8 w-fit`}>anyone else?</p>
        </div>
        <p className={`${styles.beat} ${styles.typing} ${bubble} ml-8 w-fit tracking-[0.2em] text-paper/45`}>• • •</p>
      </div>
      <p className={`${styles.beat} ${styles.close} mt-8 max-w-xs font-serif text-2xl leading-tight text-paper`}>
        Another Friday shouldn&apos;t end in the group chat.
      </p>
    </div>
  );
}
