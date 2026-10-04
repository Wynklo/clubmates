export function buttonClasses(
  variant: "primary" | "secondary" | "quiet" = "primary",
  className = "",
) {
  const base =
    "inline-flex cursor-pointer items-center justify-center rounded-full text-sm font-semibold tracking-tight transition-colors duration-200 disabled:cursor-not-allowed disabled:opacity-60";

  const variants = {
    primary: "h-12 bg-ink px-6 text-paper hover:bg-black",
    secondary: "h-12 border border-ink bg-transparent px-6 text-ink hover:border-aubergine hover:text-aubergine",
    quiet: "h-12 px-3 text-stone hover:text-ink",
  };

  return `${base} ${variants[variant]} ${className}`.trim();
}
