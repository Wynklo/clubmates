import { GapChat } from "@/components/GapChat";
import { Section } from "@/components/Section";

export function Problem() {
  return (
    <Section headerTone="dark" className="bg-ink text-paper">
      <div className="grid items-center gap-14 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)] lg:gap-16">
        <div>
          <p className="text-sm font-medium tracking-[0.18em] text-paper/70 uppercase">The gap</p>
          <h2 className="mt-4 max-w-xl text-4xl leading-[1.05] font-medium tracking-[-0.04em] text-paper sm:text-5xl lg:text-6xl">
            Great nights shouldn&apos;t depend on who&apos;s available.
          </h2>
          <p className="mt-8 max-w-md text-lg leading-8 text-paper/80">
            You already know the night you want. The hard part is someone to go with.
          </p>
        </div>
        <GapChat />
      </div>
    </Section>
  );
}
