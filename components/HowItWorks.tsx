import { Reveal } from "@/components/Reveal";
import { Section } from "@/components/Section";

const steps = [
  {
    number: "01",
    title: "Discover",
    body: "Find people in your city who want a night out, not another profile to judge.",
  },
  {
    number: "02",
    title: "Connect",
    body: "Start a conversation when there is a real plan to make, not a swipe for its own sake.",
  },
  {
    number: "03",
    title: "Go Out",
    body: "Leave with a plan. Clubmates is about the night itself.",
  },
];

export function HowItWorks() {
  return (
    <Section id="how-it-works">
      <Reveal>
        <h2 className="text-4xl font-medium tracking-[-0.04em] sm:text-5xl">How it works</h2>
      </Reveal>
      <div className="mt-14 grid gap-12 md:grid-cols-3">
        {steps.map((step, index) => (
          <Reveal key={step.number} delay={index * 0.08}>
            <p className="text-sm font-medium tracking-[0.18em] text-aubergine">{step.number}</p>
            <h3 className="mt-4 text-3xl font-medium tracking-tight">{step.title}</h3>
            <p className="mt-4 max-w-xs text-base leading-7 text-stone">{step.body}</p>
          </Reveal>
        ))}
      </div>
      <p className="mt-14 max-w-2xl text-sm leading-6 text-stone">
        These steps are what Clubmates is being built to do. Discovery, connection, and going out together
        are not live on this website yet. Early access is a list, not the product.
      </p>
    </Section>
  );
}
