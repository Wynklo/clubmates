import { Reveal } from "@/components/Reveal";
import { Section } from "@/components/Section";

const practices = [
  "Information you submit is sent over an encrypted connection and stored in a managed cloud database that encrypts data at rest.",
  "Account passwords are handled by our authentication provider. Clubmates does not keep its own copy of your password.",
  "The public website uses a limited key. Privileged database credentials are not included in the pages sent to your browser.",
  "Joining early access does not publish a profile, share your plans, or track your location.",
  "Forms are checked on the server, and raw database errors are never shown back to you.",
  "Access to the project is limited to what is needed to run this website.",
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
      </Reveal>
      <ul className="mt-12 grid gap-x-12 md:grid-cols-2">
        {practices.map((practice, index) => (
          <Reveal key={practice} delay={index * 0.04}>
            <li className="border-t border-ink/10 pt-5 text-base leading-7 text-stone">{practice}</li>
          </Reveal>
        ))}
      </ul>
      <div className="mt-16 grid gap-12 lg:grid-cols-2">
        <Reveal>
          <h3 className="text-2xl font-medium tracking-tight">What we will not pretend</h3>
          <p className="mt-4 text-base leading-7 text-stone">
            Clubmates does not hold independent security certifications, and we do not run a public
            bug-bounty program. We will not say those things until they are true. Messaging, reporting,
            and blocking are not available yet. They will be part of the product before anyone is asked
            to meet through it.
          </p>
        </Reveal>
        <Reveal delay={0.08}>
          <h3 className="text-2xl font-medium tracking-tight">If something looks wrong</h3>
          <p className="mt-4 text-base leading-7 text-stone">
            Tell us through the early access form and describe what you saw. Please do not run
            denial-of-service tests or automated scans against this site. Questions about an account
            belong with the email on that account.
          </p>
        </Reveal>
      </div>
    </Section>
  );
}
