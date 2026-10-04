import { Reveal } from "@/components/Reveal";
import { Section } from "@/components/Section";

export function Positioning() {
  return (
    <Section id="why-clubmates">
      <div className="grid gap-10 lg:grid-cols-2 lg:gap-20">
        <Reveal>
          <h2 className="text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl lg:text-6xl">
            Not another dating app.
          </h2>
        </Reveal>
        <Reveal delay={0.08}>
          <div className="max-w-xl space-y-6 text-lg leading-8 text-stone">
            <p>
              Clubmates is for social nightlife. Use it to find a plus-one or a small group for a night you
              already want — people heading the same way, not a queue of romantic matches.
            </p>
            <p>
              Dating apps are built to pair people up. That isn&apos;t the job here. If a night turns into
              something more, that&apos;s life. It isn&apos;t the product.
            </p>
          </div>
        </Reveal>
      </div>
    </Section>
  );
}
