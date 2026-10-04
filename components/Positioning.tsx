import { Section } from "@/components/Section";

export function Positioning() {
  return (
    <Section id="why-clubmates">
      <div className="grid items-start gap-8 lg:grid-cols-2 lg:gap-x-20">
        <div className="lg:sticky lg:top-24 lg:self-start">
          <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">Why Clubmates</p>
          <h2 className="mt-6 text-4xl leading-[1.02] font-medium tracking-[-0.04em] sm:text-5xl">
            Same night.
            <span className="block">Same vibe.</span>
          </h2>
        </div>
        <div className="max-w-lg lg:pt-11">
          <p className="text-pretty text-xl leading-8 text-ink">
            Clubmates is for social nightlife. Use it to find a{" "}
            <span className="whitespace-nowrap">plus-one</span> or a small group for a night you already
            want&nbsp;— people heading the same way, not a queue of romantic matches.
          </p>
          <p className="mt-6 text-pretty text-base leading-7 text-stone">
            Dating apps are built to pair people up. That isn&apos;t the job here. If a night turns into
            something more, that&apos;s life. It isn&apos;t the product.
          </p>
          <div className="mt-8 h-px w-10 bg-aubergine" />
          <p className="mt-4 text-xs font-medium tracking-[0.16em] text-aubergine uppercase">
            Social nightlife, not dating.
          </p>
        </div>
      </div>
    </Section>
  );
}
