import { Reveal } from "@/components/Reveal";
import { Section } from "@/components/Section";

export function Problem() {
  return (
    <Section>
      <Reveal>
        <h2 className="max-w-4xl text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl lg:text-6xl">
          Great nights shouldn&apos;t depend on who&apos;s available.
        </h2>
        <p className="mt-8 max-w-2xl text-lg leading-8 text-stone">
          You already know the kind of night you want. The hard part is finding someone who wants to go too.
          Clubmates is for that gap — so a free night doesn&apos;t have to be a solo one.
        </p>
      </Reveal>
    </Section>
  );
}
