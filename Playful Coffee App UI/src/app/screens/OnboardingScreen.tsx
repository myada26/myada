import React, { useState } from "react";
import { useNavigate } from "react-router";
import { Button, cn } from "../components/UI";
import { Rocket, WifiOff, Trophy, Map } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";

const slides = [
  {
    icon: Rocket,
    heading: "The Pioneer Spirit",
    body: "Inspired by Ada Lovelace, MyADA helps you master code even without a signal. You were born to create.",
  },
  {
    icon: WifiOff,
    heading: "No Signal? No Problem.",
    body: "Your lessons stay with you. Learn, practice, and code anywhere—no Wi-Fi or data required.",
  },
  {
    icon: Trophy,
    heading: "Be the Pride of Your Batch",
    body: "Your hard work deserves to be seen. Rise to the top of the college leaderboard and show your batchmates what you're capable of.",
  },
  {
    icon: Map,
    heading: "Your Story Starts Here",
    body: "No more feeling left behind. We find your level and guide you step-by-step toward your future in tech.",
  },
];

export default function OnboardingScreen() {
  const navigate = useNavigate();
  const [currentSlide, setCurrentSlide] = useState(0);

  const isLast = currentSlide === slides.length - 1;

  const handleNext = () => {
    if (isLast) {
      navigate("/permissions");
    } else {
      setCurrentSlide((prev) => prev + 1);
    }
  };

  const Icon = slides[currentSlide].icon;

  return (
    <div className="flex-1 flex flex-col bg-[#F4EFEA] p-6">
      {/* Top Header */}
      <div className="flex justify-end pt-4 pb-8">
        <button
          onClick={() => navigate("/entry-point")}
          className="text-[#1F2937] opacity-60 font-medium hover:opacity-100 transition-opacity"
        >
          Skip
        </button>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center -mt-12">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentSlide}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="flex flex-col items-center text-center max-w-sm w-full"
          >
            {/* Illustration Area */}
            <div className="w-48 h-48 bg-[#E89C1E]/10 rounded-full flex items-center justify-center mb-10 border border-[#E89C1E]/30 relative">
              <Icon size={80} className="text-[#E89C1E] relative z-10" />
              {/* Optional decor circle */}
              <div className="absolute -inset-4 rounded-full border border-[dashed] border-[#E89C1E]/30 animate-spin-slow" style={{ animationDuration: '20s' }} />
            </div>

            <h2 className="text-2xl font-bold mb-4">{slides[currentSlide].heading}</h2>
            <p className="text-base text-[#1F2937]/70 leading-relaxed">
              {slides[currentSlide].body}
            </p>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom Area */}
      <div className="flex flex-col gap-8 pb-8">
        {/* Progress Bar */}
        <div className="flex justify-center gap-2">
          {slides.map((_, i) => (
            <div
              key={i}
              className={cn(
                "h-2 rounded-full transition-all duration-300",
                i === currentSlide ? "w-6 bg-[#1E3A8A]" : "w-2 bg-[#1E3A8A]/20"
              )}
            />
          ))}
        </div>

        {/* Action Button */}
        <Button variant="primary" className="w-full" onClick={handleNext}>
          {isLast ? "Get Started" : "Next"}
        </Button>
      </div>
    </div>
  );
}
