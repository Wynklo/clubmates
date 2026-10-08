"use client";

import { AnimatePresence, motion } from "framer-motion";
import { useEffect, useRef, useState } from "react";
import { Avatar } from "@/components/Avatar";
import { useEarlyAccess } from "@/components/EarlyAccessProvider";
import { arjun, dev, leah, lee, maya, nia, sam, type Person } from "@/components/people";
import { Section } from "@/components/Section";
import { buttonClasses } from "@/components/ui/button";
import styles from "./EarlyAccessSection.module.css";

const pool: Person[] = [nia, dev, sam, lee, leah, maya, arjun];
const pauses = [6200, 7400, 6800, 8200];
const ease = [0.22, 1, 0.36, 1] as const;

type Face = { id: number; person: Person };

function openingRow(): Face[] {
  return pool.slice(0, 5).map((person, id) => ({ id, person }));
}

function Community() {
  const [faces, setFaces] = useState<Face[]>(openingRow);
  const [badge, setBadge] = useState<"joining" | "plus" | null>(null);
  const [sparkId, setSparkId] = useState<number | null>(null);
  const [tuck, setTuck] = useState(false);
  const [arrivedId, setArrivedId] = useState<number | null>(null);
  const [canHover, setCanHover] = useState(false);
  const [reduced, setReduced] = useState(false);
  const limitRef = useRef(6);
  const countRef = useRef(5);
  const nextId = useRef(5);
  const nextPerson = useRef(5);
  const joins = useRef(0);

  useEffect(() => {
    const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
    const hoverQuery = window.matchMedia("(hover: hover) and (pointer: fine)");
    const widthQuery = window.matchMedia("(max-width: 639px)");

    const apply = () => {
      setReduced(motionQuery.matches);
      setCanHover(hoverQuery.matches);
      limitRef.current = widthQuery.matches ? 5 : 6;
      if (motionQuery.matches) {
        countRef.current = 5;
        setFaces(openingRow());
        setBadge(null);
        setSparkId(null);
        setTuck(false);
        return;
      }
      setFaces((current) => {
        if (current.length <= limitRef.current) return current;
        const trimmed = current.slice(-limitRef.current);
        countRef.current = trimmed.length;
        return trimmed;
      });
    };

    apply();
    motionQuery.addEventListener("change", apply);
    hoverQuery.addEventListener("change", apply);
    widthQuery.addEventListener("change", apply);
    return () => {
      motionQuery.removeEventListener("change", apply);
      hoverQuery.removeEventListener("change", apply);
      widthQuery.removeEventListener("change", apply);
    };
  }, []);

  useEffect(() => {
    if (reduced) return;

    let cancelled = false;
    const timers = new Set<number>();
    const later = (fn: () => void, ms: number) => {
      const id = window.setTimeout(() => {
        timers.delete(id);
        if (!cancelled) fn();
      }, ms);
      timers.add(id);
    };

    const join = () => {
      const id = nextId.current;
      nextId.current += 1;
      const person = pool[nextPerson.current % pool.length];
      nextPerson.current += 1;
      joins.current += 1;
      const withJoining = joins.current % 4 === 0;

      const arrive = () => {
        setBadge("plus");
        setArrivedId(id);
        if (countRef.current < limitRef.current) {
          setTuck(true);
          later(() => setTuck(false), 700);
        }
        setFaces((current) => {
          const next = [...current, { id, person }];
          const trimmed = next.length > limitRef.current ? next.slice(next.length - limitRef.current) : next;
          countRef.current = trimmed.length;
          return trimmed;
        });
        later(() => setSparkId(id), 640);
        later(() => setSparkId((current) => (current === id ? null : current)), 1400);
        later(() => setBadge(null), 1600);
        later(join, pauses[joins.current % pauses.length]);
      };

      if (withJoining) {
        setBadge("joining");
        later(arrive, 500);
      } else {
        arrive();
      }
    };

    const schedule = () => {
      later(join, pauses[joins.current % pauses.length]);
    };

    schedule();

    return () => {
      cancelled = true;
      timers.forEach((id) => window.clearTimeout(id));
    };
  }, [reduced]);

  return (
    <div className="lg:pt-14">
      <div className="relative w-[218px] pt-5 sm:w-[260px]">
        <AnimatePresence>
          {badge ? (
            <motion.span
              key={badge}
              aria-hidden="true"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: -2 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.45, ease: "easeOut" }}
              className="pointer-events-none absolute top-0 right-0 text-[11px] leading-none font-medium tracking-wide text-aubergine"
            >
              {badge === "joining" ? "joining..." : "+1"}
            </motion.span>
          ) : null}
        </AnimatePresence>
        <div className="flex items-center" aria-hidden="true">
          <AnimatePresence mode="popLayout" initial={false}>
            {faces.map((face) => (
              <motion.span
                key={face.id}
                layout
                initial={{ opacity: 0, scale: 0.82, x: 22 }}
                animate={{ opacity: 1, scale: 1, x: tuck && face.id !== arrivedId ? -8 : 0 }}
                exit={{ opacity: 0, x: -18, scale: 0.9 }}
                transition={{ duration: 0.8, ease }}
                whileHover={canHover ? { y: -2, scale: 1.04 } : undefined}
                className={`relative -ml-2 inline-flex rounded-full first:ml-0 ${
                  arrivedId === face.id ? styles.arrive : ""
                }`}
              >
                <span className="inline-flex size-[3.125rem] overflow-hidden rounded-full ring-2 ring-paper">
                  <Avatar person={face.person} />
                </span>
                {sparkId === face.id ? (
                  <span className={`${styles.spark} pointer-events-none absolute -top-2 -right-1 text-[10px] leading-none text-aubergine`}>
                    ✦
                  </span>
                ) : null}
              </motion.span>
            ))}
          </AnimatePresence>
        </div>
      </div>
      <p className="mt-4 text-sm leading-6 text-stone lg:text-right">People heading the same way.</p>
    </div>
  );
}

export function EarlyAccessSection() {
  const { open } = useEarlyAccess();
  const copyRef = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const node = copyRef.current;
    if (!node) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        setShown(true);
        observer.disconnect();
      },
      { threshold: 0.4 },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  return (
    <Section id="early-access" className="bg-blush">
      <div className="grid items-start gap-14 lg:grid-cols-[minmax(0,1.15fr)_auto] lg:gap-20">
        <div ref={copyRef} className={`max-w-xl ${shown ? styles.shown : ""}`}>
          <p className={`${styles.line} text-sm font-medium tracking-[0.18em] text-aubergine uppercase`}>
            Early access
          </p>
          <h2
            className={`${styles.line} mt-4 text-4xl leading-[1.05] font-medium tracking-[-0.04em] sm:text-5xl`}
            style={{ animationDelay: "60ms" }}
          >
            Your city&apos;s going out.
            <span className="mt-2 block">Be there when Clubmates opens.</span>
          </h2>
          <p className={`${styles.line} mt-6 text-lg leading-8 text-stone`} style={{ animationDelay: "120ms" }}>
            Join early access and we&apos;ll let you know when Clubmates starts bringing nights together in
            your city.
          </p>
          <div className={`${styles.line} mt-10`} style={{ animationDelay: "180ms" }}>
            <button type="button" className={`${buttonClasses("primary")} ${styles.cta}`} onClick={open}>
              Get Early Access
            </button>
          </div>
        </div>
        <Community />
      </div>
    </Section>
  );
}
