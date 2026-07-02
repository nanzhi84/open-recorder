import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import type { ReactElement } from "react";

const docsUrl: string = "https://docs.openrecorder.xyz/";
const sourceUrl: string = "https://github.com/imbhargav5/open-recorder";

export const metadata: Metadata = {
  title: "Open Recorder | 原生 macOS 录屏工作台",
  description:
    "Open Recorder 是一个开源 macOS 录屏、截图和原生编辑工具，使用 Swift 与 Rust 构建。",
};

type ProofPoint = readonly [value: string, label: string];

type LandingContentBlock = Readonly<{
  title: string;
  eyebrow: string;
  copy: string;
}>;

type WorkflowStep = Readonly<{
  step: string;
  title: string;
  copy: string;
}>;

type ArchitectureNote = Readonly<{
  label: string;
  value: string;
}>;

const proofPoints: readonly ProofPoint[] = [
  ["原生 macOS", "Swift 捕捉界面，沿用系统隐私授权流程"],
  ["本地优先", "录制、截图和项目文件保留在你的 Mac 上"],
  ["开源", "Apache 2.0，轻量 Swift + Rust 技术栈"],
  ["内置编辑器", "缩放、摄像头片段、光标叠加和导出"],
];

const featureHighlights: readonly LandingContentBlock[] = [
  {
    title: "只捕捉真正重要的内容",
    eyebrow: "显示器、窗口或区域",
    copy: "选择完整显示器、单个应用窗口，或手绘精确区域；录制前可配置麦克风、系统声音、摄像头、光标和点击效果。",
  },
  {
    title: "在时间线上整理叙事节奏",
    eyebrow: "缩放、片段、光标、摄像头",
    copy: "添加手动或自动缩放区段，分割片段，调整播放速度，设置光标运动样式，并独立摆放摄像头片段。",
  },
  {
    title: "完成可交付的最终素材",
    eyebrow: "裁剪、比例、截图、导出",
    copy: "为固定比例布局裁剪和重构视频，在样式化背景上合成截图，并导出 MOV、MP4、GIF 或 PNG。",
  },
];

const workflow: readonly WorkflowStep[] = [
  {
    step: "01",
    title: "选择来源",
    copy: "选择显示器、窗口或手绘区域，使用贴合 macOS 的捕捉流程。",
  },
  {
    step: "02",
    title: "录制或截图",
    copy: "视频保存到 Movies，截图保存到 Pictures，并自动生成项目元数据。",
  },
  {
    step: "03",
    title: "编辑时间线",
    copy: "通过裁剪、速度调整、缩放效果、光标叠加和独立摄像头片段完善素材。",
  },
  {
    step: "04",
    title: "导出或合成",
    copy: "导出 MOV、MP4、GIF 或 PNG，支持裁剪、比例、样式背景和截图合成。",
  },
];

const architectureNotes: readonly ArchitectureNote[] = [
  {
    label: "Swift 应用",
    value: "捕捉界面、编辑时间线、截图合成、Finder 集成和隐私授权",
  },
  {
    label: "Rust 服务",
    value: "项目元数据、路径处理、截图索引和导出记录",
  },
  {
    label: "本地路径",
    value: "~/Movies/Open Recorder、~/Pictures/Open Recorder 和本地项目文件",
  },
];

function GitHubIcon(): ReactElement {
  return (
    <svg
      aria-hidden="true"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="currentColor"
      focusable="false"
    >
      <path d="M12 .5C5.65.5.5 5.65.5 12c0 5.09 3.29 9.4 7.86 10.92.58.11.79-.25.79-.56 0-.28-.01-1.02-.02-2-3.2.7-3.88-1.54-3.88-1.54-.52-1.33-1.28-1.69-1.28-1.69-1.05-.72.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.77 2.7 1.26 3.36.96.1-.75.4-1.26.73-1.55-2.56-.29-5.25-1.28-5.25-5.69 0-1.26.45-2.28 1.19-3.09-.12-.29-.52-1.47.11-3.05 0 0 .97-.31 3.17 1.18.92-.26 1.9-.38 2.88-.39.98 0 1.96.13 2.88.39 2.2-1.49 3.17-1.18 3.17-1.18.63 1.58.23 2.76.11 3.05.74.81 1.19 1.83 1.19 3.09 0 4.42-2.7 5.39-5.27 5.68.42.36.79 1.07.79 2.16 0 1.56-.01 2.82-.01 3.2 0 .31.21.68.8.56A11.51 11.51 0 0 0 23.5 12C23.5 5.65 18.35.5 12 .5Z" />
    </svg>
  );
}

export default function ChineseHome(): ReactElement {
  return (
    <main lang="zh-CN">
      <nav className="top-nav" aria-label="主导航">
        <div className="nav-inner">
          <a className="brand-mark" href="#top" aria-label="Open Recorder 首页">
            <Image
              src="/open-recorder-brand-image.png"
              alt=""
              width={28}
              height={28}
              priority
              unoptimized
            />
            <span>Open Recorder</span>
          </a>
          <div className="nav-links">
            <a className="section-link" href="#features">功能</a>
            <a className="section-link" href="#workflow">流程</a>
            <a className="section-link" href="#architecture">架构</a>
            <Link className="language-link" href="/">English</Link>
            <a className="primary-action" href={docsUrl} target="_blank" rel="noopener noreferrer">
              文档
            </a>
          </div>
        </div>
      </nav>

      <section className="hero-section" id="top">
        <div className="section-inner hero-inner">
          <p className="eyebrow">原生 macOS 录屏工作台</p>
          <h1>Open Recorder</h1>
          <p className="hero-lede">
            录制屏幕、捕捉截图，在原生时间线上调整缩放、光标和摄像头，
            然后导出精致的 MOV、MP4、GIF 或 PNG，无需云端处理。
          </p>
          <div className="hero-actions">
            <a className="primary-action" href={docsUrl} target="_blank" rel="noopener noreferrer">
              文档
            </a>
            <a
              className="secondary-action"
              href={sourceUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              <GitHubIcon /> 源码
            </a>
          </div>

          <div className="hero-media" aria-label="Open Recorder 产品演示">
            <Image
              src="/open-recorder-demo.gif"
              alt="Open Recorder 应用演示，展示 macOS 捕捉工作流"
              width={1280}
              height={720}
              priority
              unoptimized
            />
          </div>
        </div>
      </section>

      <section className="proof-band" aria-label="项目亮点">
        <div className="section-inner proof-grid">
          {proofPoints.map(([value, label]) => (
            <div className="proof-item" key={value}>
              <strong>{value}</strong>
              <span>{label}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="section-shell feature-section" id="features">
        <div className="section-inner">
          <div className="section-heading">
            <p className="eyebrow">捕捉、编辑、导出</p>
            <h2>一个面向产品演示、文档和可分享短片的原生捕捉工作台。</h2>
          </div>

          <div className="feature-grid">
            {featureHighlights.map((feature) => (
              <article className="feature-card" key={feature.title}>
                <p>{feature.eyebrow}</p>
                <h3>{feature.title}</h3>
                <span>{feature.copy}</span>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="workflow-section" id="workflow">
        <div className="section-inner workflow-inner">
          <div className="workflow-copy">
            <p className="eyebrow">为重复工作而设计</p>
            <h2>每一次捕捉都经过一条清晰、安静、本地的流程。</h2>
          </div>

          <ol className="workflow-list">
            {workflow.map((item) => (
              <li key={item.step}>
                <span>{item.step}</span>
                <div>
                  <h3>{item.title}</h3>
                  <p>{item.copy}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="architecture-section" id="architecture">
        <div className="section-inner architecture-inner">
          <div>
            <p className="eyebrow">本地优先架构</p>
            <h2>需要贴近 Mac 的地方交给 Swift，需要耐久性的地方交给 Rust。</h2>
          </div>

          <div className="architecture-panel">
            {architectureNotes.map((note) => (
              <div className="architecture-row" key={note.label}>
                <strong>{note.label}</strong>
                <span>{note.value}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="closing-section">
        <div className="section-inner closing-inner">
          <div>
            <p className="eyebrow">GitHub 开源项目</p>
            <h2>让你的下一条产品演示真正完成。</h2>
          </div>
          <a className="primary-action" href={sourceUrl} target="_blank" rel="noopener noreferrer">
            查看仓库
          </a>
        </div>
      </section>

      <footer className="site-footer">
        <div className="section-inner footer-inner">
          <span>Open Recorder</span>
          <span>Apache 2.0 · 使用 Swift 和 Rust 构建</span>
        </div>
      </footer>
    </main>
  );
}
