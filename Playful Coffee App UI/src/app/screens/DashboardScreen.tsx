import React, { useState } from "react";
import { Button, Input, Card, cn } from "./components/UI";
import { AppIcons, AppIllustrations } from "./components/Assets";
import { ImageWithFallback } from "./components/figma/ImageWithFallback";
import { motion, AnimatePresence } from "motion/react";

export default function DashboardScreen() {
  const [activeTab, setActiveTab] = useState("Home");
  const [inputValue, setInputValue] = useState("");

  const tabs = [
    { id: "Home", icon: AppIcons.Home },
    { id: "Code", icon: AppIcons.Code },
    { id: "Leaderboard", icon: AppIcons.Leaderboard },
    { id: "Profile", icon: AppIcons.Profile },
  ];

  return (
    <div className="min-h-screen bg-[#F4EFEA] font-sans text-[#1F2937] flex justify-center">
      {/* Mobile Container */}
      <div className="w-full max-w-md bg-[#F4EFEA] shadow-2xl relative flex flex-col min-h-screen overflow-hidden border-x-[1.5px] border-[#2D2D2D]/10">
        
        {/* Top Header */}
        <header className="px-6 pt-12 pb-4 flex items-center justify-between sticky top-0 bg-[#F4EFEA]/80 backdrop-blur-md z-10">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full overflow-hidden border-[1.5px] border-[#2D2D2D]">
              <ImageWithFallback 
                src="/src/imports/Fallin.png" 
                alt="Profile Avatar" 
                className="w-full h-full object-cover" 
              />
            </div>
            <div>
              <p className="text-sm font-medium opacity-60">Good morning,</p>
              <h1 className="text-xl font-bold tracking-tight">Maker</h1>
            </div>
          </div>
          <button className="w-10 h-10 rounded-full border-[1.5px] border-[#2D2D2D] flex items-center justify-center hover:bg-black/5 transition-colors">
            <AppIcons.Settings size={20} />
          </button>
        </header>

        {/* Scrollable Content */}
        <main className="flex-1 overflow-y-auto px-6 pb-28 pt-4 space-y-8 no-scrollbar">
          
          {/* Highlight Card Section */}
          <section>
            <div className="flex justify-between items-end mb-4">
              <h2 className="text-lg font-bold">Your Progress</h2>
            </div>
            <Card variant="highlight" className="relative overflow-hidden group">
              <div className="relative z-10 w-2/3">
                <h3 className="text-2xl font-bold text-[#1E3A8A] mb-2">Keep it up!</h3>
                <p className="text-sm opacity-80 text-[#1E3A8A] mb-4">You're on a 5-day coding streak. 3 more days for a star!</p>
                <Button variant="primary" size="sm" className="px-4 py-2 h-auto text-sm">
                  Continue Lesson
                </Button>
              </div>
              <div className="absolute -right-4 -bottom-4 w-32 h-32 opacity-80 group-hover:scale-105 transition-transform duration-500">
                <AppIllustrations.ProgressGraph className="w-full h-full text-[#E89C1E]" />
              </div>
            </Card>
          </section>

          {/* Component Showcase - Inputs */}
          <section>
            <h2 className="text-lg font-bold mb-4">Join a challenge</h2>
            <div className="space-y-3">
              <Input 
                placeholder="Enter invite code..." 
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
              />
              <Input 
                placeholder="Error state example" 
                error
                defaultValue="Invalid code!"
              />
            </div>
          </section>

          {/* Quick Actions / Doodles */}
          <section>
            <h2 className="text-lg font-bold mb-4">Explore</h2>
            <div className="grid grid-cols-2 gap-4">
              <Card variant="basic" className="flex flex-col items-center justify-center text-center gap-3 cursor-pointer hover:bg-[#FAF8F5]">
                <div className="w-16 h-16 bg-[#E89C1E]/10 rounded-full flex items-center justify-center mb-2 border border-[#E89C1E]/30">
                  <AppIllustrations.LaptopCoding className="w-10 h-10" />
                </div>
                <span className="font-semibold text-sm">Daily Code</span>
              </Card>
              <Card variant="basic" className="flex flex-col items-center justify-center text-center gap-3 cursor-pointer hover:bg-[#FAF8F5]">
                <div className="w-16 h-16 bg-[#1E3A8A]/10 rounded-full flex items-center justify-center mb-2 border border-[#1E3A8A]/30">
                  <AppIllustrations.AchievementStar className="w-10 h-10" />
                </div>
                <span className="font-semibold text-sm">Achievements</span>
              </Card>
            </div>
          </section>

          {/* List Cards */}
          <section>
            <h2 className="text-lg font-bold mb-4">Recent Activity</h2>
            <div className="space-y-3">
              <Card variant="list">
                <div className="w-12 h-12 bg-[#F4EFEA] rounded-full border-[1.5px] border-[#2D2D2D] flex items-center justify-center mr-4 shrink-0">
                  <AppIcons.Code size={20} className="text-[#1E3A8A]" />
                </div>
                <div className="flex-1">
                  <h4 className="font-bold text-sm">React Basics</h4>
                  <p className="text-xs opacity-60">Completed 2 hours ago</p>
                </div>
                <div className="text-xs font-bold text-[#E89C1E] bg-[#E89C1E]/10 px-2 py-1 rounded-md border border-[#E89C1E]/30">
                  +50 XP
                </div>
              </Card>
              
              <Card variant="list" className="opacity-70">
                <div className="w-12 h-12 bg-[#F4EFEA] rounded-full border-[1.5px] border-[#2D2D2D] flex items-center justify-center mr-4 shrink-0">
                  <AppIllustrations.OfflineCloud className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <h4 className="font-bold text-sm text-[#CA2B2C]">Sync Failed</h4>
                  <p className="text-xs opacity-60">Tap to retry</p>
                </div>
                <Button variant="secondary" size="sm" className="h-8 px-3 text-xs">
                  Retry
                </Button>
              </Card>
            </div>
          </section>

          {/* Buttons Showcase */}
          <section className="pt-4 border-t-[1.5px] border-[#2D2D2D]/10">
            <h2 className="text-lg font-bold mb-4">Button Variants</h2>
            <div className="flex flex-col gap-3">
              <Button variant="primary">Primary Button</Button>
              <Button variant="secondary">Secondary Button</Button>
              <Button variant="text">Text Button</Button>
            </div>
          </section>

        </main>

        {/* Bottom Navigation */}
        <div className="absolute bottom-0 left-0 right-0 bg-[#F4EFEA] border-t-[1.5px] border-[#2D2D2D] px-6 py-4 flex justify-between items-center z-20 pb-safe">
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            const Icon = tab.icon;
            return (
              <button 
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={cn(
                  "flex flex-col items-center justify-center gap-1 p-2 transition-colors relative",
                  isActive ? "text-[#1E3A8A]" : "text-[#1F2937]/50 hover:text-[#1F2937]/80"
                )}
              >
                <Icon size={24} />
                <span className="text-[10px] font-bold">{tab.id}</span>
                {isActive && (
                  <motion.div 
                    layoutId="nav-indicator"
                    className="absolute -top-3 w-1 h-1 bg-[#1E3A8A] rounded-full"
                  />
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
