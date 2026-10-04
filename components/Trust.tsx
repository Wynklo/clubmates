import { ArrowRight } from "lucide-react";
import Link from "next/link";
import { Section } from "@/components/Section";

const items = [
  {
    number: "01",
    title: "18+ only",
    body: "Built for adults. Joining the list confirms you are 18 or older.",
  },
  {
    number: "02",
    title: "Private by default",
    body: "Early access does not publish your profile, plans, or location.",
  },
  {
    number: "03",
    title: "Secure",
    body: "What you submit is encrypted in transit and at rest.",
  },
  {
    number: "04",
    title: "Safety first",
    body: "Messaging, reporting, and blocking are not live yet.",
  },
];

export function Trust() {
  return (
    <Section id="safety">
      <p className="text-sm font-medium tracking-[0.18em] text-aubergine uppercase">Trust</p>
      <h2 className="mt-4 max-w-3xl text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl">
        Good nights start
        <span className="block">with trust.</span>
      </h2>
      <p className="mt-6 max-w-xl text-lg leading-8 text-stone">
        Meeting new people should still leave you in control.
      </p>
      <div className="mt-16 grid gap-x-8 gap-y-12 sm:grid-cols-2 lg:grid-cols-4 lg:grid-rows-[auto_auto_auto] lg:gap-y-0">
        {items.map((item) => (
          <article
            key={item.number}
            className="grid grid-rows-[auto_auto_auto] border-t border-ink/10 pt-6 lg:row-span-3 lg:grid-rows-subgrid"
          >
            <p className="font-serif text-5xl leading-none font-medium tracking-[-0.04em] text-aubergine">
              {item.number}
            </p>
            <h3 className="mt-5 text-xl leading-7 font-medium tracking-tight">{item.title}</h3>
            <p className="mt-3 text-pretty text-base leading-7 text-stone">{item.body}</p>
          </article>
        ))}
      </div>
      <div id="security" className="mt-14 flex flex-col gap-4 sm:flex-row sm:items-center sm:gap-8">
        <a href="#safety" className="group inline-flex items-center gap-1.5 text-sm font-semibold text-aubergine">
          Safety
          <ArrowRight
            className="size-3.5 transition-transform duration-200 group-hover:translate-x-0.5 motion-reduce:transition-none"
            aria-hidden="true"
          />
        </a>
        <Link href="/security" className="group inline-flex items-center gap-1.5 text-sm font-semibold text-aubergine">
          Privacy
          <ArrowRight
            className="size-3.5 transition-transform duration-200 group-hover:translate-x-0.5 motion-reduce:transition-none"
            aria-hidden="true"
          />
        </Link>
      </div>
      <p className="mt-6 max-w-xl text-sm leading-6 text-stone">
        Messaging, reporting, and blocking are still being designed for launch. Clubmates does not hold
        security certifications or run a bug bounty. If something looks wrong, tell us through the early access
        form.
      </p>
    </Section>
  );
}
