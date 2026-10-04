import { Reveal } from "@/components/Reveal";
import { Section } from "@/components/Section";

const points = [
  {
    title: "Adults only",
    body: "Joining early access or creating an account means confirming you are 18 or older. Clubmates is not for minors.",
  },
  {
    title: "Nothing is published",
    body: "This website does not track your location. Joining the list does not create a public profile or share your plans.",
  },
  {
    title: "Safety tools come first",
    body: "Messaging, reporting, and blocking are not available yet. They will be part of Clubmates before anyone is asked to meet through the product.",
  },
];

export function Safety() {
  return (
    <Section id="safety">
      <Reveal>
        <h2 className="max-w-3xl text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl">
          Good nights start with trust.
        </h2>
        <p className="mt-6 max-w-2xl text-lg leading-8 text-stone">
          Trust starts with being clear about what exists today.
        </p>
      </Reveal>
      <div className="mt-14 grid gap-10 md:grid-cols-3">
        {points.map((point, index) => (
          <Reveal key={point.title} delay={index * 0.08}>
            <h3 className="text-xl font-medium tracking-tight">{point.title}</h3>
            <p className="mt-3 text-base leading-7 text-stone">{point.body}</p>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
