import React from "react";
import {
  Home,
  User,
  Code2,
  Trophy,
  Settings,
  CloudOff,
  Laptop,
  TrendingUp,
  Star,
  type LucideProps
} from "lucide-react";

// ----------------------------------------------------------------------
// ICONS
// ----------------------------------------------------------------------
const iconStyle = {
  strokeWidth: 1.8,
  color: "#1F2937",
};

export const AppIcons = {
  Home: (props: LucideProps) => <Home {...iconStyle} {...props} />,
  Profile: (props: LucideProps) => <User {...iconStyle} {...props} />,
  Code: (props: LucideProps) => <Code2 {...iconStyle} {...props} />,
  Leaderboard: (props: LucideProps) => <Trophy {...iconStyle} {...props} />,
  Settings: (props: LucideProps) => <Settings {...iconStyle} {...props} />,
};

// ----------------------------------------------------------------------
// ILLUSTRATIONS (Custom SVG doodles)
// ----------------------------------------------------------------------
export const AppIllustrations = {
  LaptopCoding: (props: React.SVGProps<SVGSVGElement>) => (
    <svg
      width="64"
      height="64"
      viewBox="0 0 64 64"
      fill="none"
      stroke="#1F2937"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      {/* Hand-drawn laptop base */}
      <path d="M10 46 C20 45, 44 45, 54 46" />
      <path d="M10 46 C8 49, 6 52, 4 54 C20 55, 44 55, 60 54 C58 52, 56 49, 54 46" />
      {/* Screen */}
      <path d="M14 46 C15 30, 14 16, 16 14 C30 13, 40 13, 48 14 C50 16, 49 30, 50 46" />
      {/* Code symbols */}
      <path d="M24 26 C22 28, 22 30, 24 32" stroke="#1E3A8A" />
      <path d="M40 26 C42 28, 42 30, 40 32" stroke="#1E3A8A" />
      <path d="M30 34 L34 24" stroke="#E89C1E" />
    </svg>
  ),

  OfflineCloud: (props: React.SVGProps<SVGSVGElement>) => (
    <svg
      width="64"
      height="64"
      viewBox="0 0 64 64"
      fill="none"
      stroke="#1F2937"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      {/* Hand-drawn cloud */}
      <path d="M22 40 C14 42, 10 34, 14 26 C16 18, 28 14, 34 20 C42 16, 52 22, 50 32 C56 36, 50 44, 42 42" />
      {/* Crossed out line in Brand Red */}
      <path d="M12 12 C25 25, 39 39, 52 52" stroke="#CA2B2C" strokeWidth="3" />
    </svg>
  ),

  ProgressGraph: (props: React.SVGProps<SVGSVGElement>) => (
    <svg
      width="64"
      height="64"
      viewBox="0 0 64 64"
      fill="none"
      stroke="#1F2937"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      {/* Axes */}
      <path d="M10 10 C11 25, 9 40, 10 54 C25 53, 40 55, 54 54" />
      {/* Wobbly rising line */}
      <path d="M16 48 C24 40, 28 42, 34 30 C38 22, 42 24, 50 14" stroke="#E89C1E" strokeWidth="3" />
      {/* Nodes on graph */}
      <circle cx="16" cy="48" r="3" fill="#F4EFEA" />
      <circle cx="34" cy="30" r="3" fill="#F4EFEA" />
      <circle cx="50" cy="14" r="3" fill="#F4EFEA" />
    </svg>
  ),

  AchievementStar: (props: React.SVGProps<SVGSVGElement>) => (
    <svg
      width="64"
      height="64"
      viewBox="0 0 64 64"
      fill="none"
      stroke="#1F2937"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      {/* Wobbly star */}
      <path d="M32 8 C34 18, 36 22, 44 26 C52 30, 46 36, 42 42 C40 50, 34 46, 32 44 C26 48, 22 48, 24 40 C18 34, 16 28, 22 26 C28 22, 30 18, 32 8 Z" fill="#E89C1E" stroke="#1F2937" />
      {/* Twinkles */}
      <path d="M12 16 L14 18 M16 12 L14 14" stroke="#1E3A8A" />
      <path d="M52 14 L50 16 M54 20 L52 18" stroke="#1E3A8A" />
      <path d="M48 54 L46 52 M52 52 L50 50" stroke="#1E3A8A" />
    </svg>
  ),
};
