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
        className="h-7 w-auto sm:h-10"
      />
      <span className="text-[0.95rem] font-extrabold tracking-[-0.05em] lowercase sm:text-[1.2rem]">
        club<span className={onDark ? "text-blush" : "text-aubergine"}>mates</span>
      </span>
    </span>
  );
}
