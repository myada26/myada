import React, { useEffect } from "react";
import { useNavigate } from "react-router";
import { Code2 } from "lucide-react";
import { motion } from "motion/react";

export default function SplashScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate("/onboarding");
    }, 1500);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="flex-1 flex flex-col items-center justify-center bg-[#F4EFEA]">
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5 }}
        className="flex flex-col items-center justify-center gap-4"
      >
        <div className="flex items-center gap-2">
          <Code2 size={48} className="text-[#1E3A8A]" />
          <h1 className="text-4xl font-bold tracking-tight text-[#1E3A8A]">MyADA</h1>
        </div>
        <p className="text-lg font-medium opacity-70 text-[#1F2937]">Learning Has No Limits.</p>
      </motion.div>
    </div>
  );
}
