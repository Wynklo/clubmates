import { Reveal } from "@/components/Reveal";
import { Section } from "@/components/Section";

const points = [
  {
    title: "Encrypted",
    body: "What you submit travels over an encrypted connection and is stored in a database that encrypts data at rest.",
  },
  {
    title: "Limited access",
    body: "The site uses a public key only. Privileged database credentials never reach your browser.",
  },
  {
    title: "Nothing public",
    body: "Early access does not publish a profile, share your plans, or track your location.",
  },
];

export function Security({ title = "h2" }: { title?: "h1" | "h2" }) {
  const Title = title;
  return (
    <Section id="security">
      <Reveal>
        <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">Security</p>
        <Title className="mt-4 max-w-3xl text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl">
          Privacy comes before the night out.
        </Title>
        <p className="mt-6 max-w-2xl text-lg leading-8 text-stone">
          What this website does with the details you share.
        </p>
      </Reveal>
      <div className="mt-14 grid gap-6 md:grid-cols-3">
        {points.map((point, index) => (
          <Reveal key={point.title} delay={index * 0.08}>
            <article className="h-full border-t-2 border-ink pt-6">
              <h2 className="text-3xl font-medium tracking-tight">{point.title}</h2>
              <p className="mt-4 max-w-xs text-base leading-7 text-stone">{point.body}</p>
            </article>
          </Reveal>
        ))}
      </div>
      <p className="mt-14 max-w-2xl border-l-2 border-aubergine pl-4 text-sm leading-6 text-stone">
        Clubmates does not hold security certifications or run a bug bounty. Messaging, reporting, and
        blocking are not live yet. If something looks wrong, tell us through the early access form.
        Please do not scan or load-test this site.
      </p>
    </Section>
  );
}
