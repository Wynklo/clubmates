import { Section } from "@/components/Section";

export function Idea() {
  return (
    <Section className="bg-blush/40">
      <div className="mx-auto max-w-3xl text-center">
        <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">The idea</p>
        <p className="mt-6 font-serif text-3xl leading-snug font-medium tracking-[-0.03em] sm:text-4xl">
          You already know where you want to go.
          <span className="mt-2 block">You just need someone heading the same way.</span>
        </p>
        <p className="mt-8 text-sm leading-6 text-stone">Find someone. Meet. Go together.</p>
      </div>
    </Section>
  );
}
