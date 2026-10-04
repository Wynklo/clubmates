type LogoProps = {
  className?: string;
  markClassName?: string;
};

export function Logo({ className = "", markClassName = "h-8 w-8" }: LogoProps) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <svg viewBox="0 0 32 32" fill="none" aria-hidden="true" className={markClassName}>
        <path
          d="M8.2 22.2c.8-3.5 2.4-5.2 4.3-5.2 1.6 0 2.7.9 3.4 2.2"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
        />
        <path
          d="M23.8 22.2c-.8-3.5-2.4-5.2-4.3-5.2-1.6 0-2.7.9-3.4 2.2"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
        />
        <circle cx="12.2" cy="11.4" r="2.2" fill="currentColor" />
        <circle cx="19.8" cy="11.4" r="2.2" fill="currentColor" />
        <circle cx="16" cy="16.7" r="1.15" fill="#67295F" />
      </svg>
      <span className="text-[1.05rem] font-semibold tracking-[-0.04em]">Clubmates</span>
    </span>
  );
}
