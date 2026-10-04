import Image from "next/image";
import logo from "@/assets/clubmates-mark.png";

type LogoProps = {
  className?: string;
  onDark?: boolean;
  priority?: boolean;
};

export function Logo({ className = "", onDark = false, priority = false }: LogoProps) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <Image
        src={logo}
        alt=""
        priority={priority}
        sizes="72px"
        className="h-10 w-auto"
        style={{ width: "auto", height: "2.5rem" }}
      />
      <span className="text-[1.2rem] font-extrabold tracking-[-0.05em] lowercase">
        club<span className={onDark ? "text-blush" : "text-aubergine"}>mates</span>
      </span>
    </span>
  );
}
