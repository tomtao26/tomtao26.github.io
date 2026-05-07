# Yixin Tao Markdown Homepage

这是一个可以用 Markdown 维护的 GitHub Pages 学术主页版本。日常维护基本只需要编辑 `index.md`。

## 文件结构

```text
.
├── index.md              # 主要内容：个人简介、研究方向、论文列表
├── _layouts/home.html    # 页面模板，一般不用改
├── assets/styles.css     # 视觉样式，一般不用改
├── assets/script.js      # 移动端菜单、论文搜索、复制邮箱，一般不用改
├── assets/favicon.svg    # 网站图标
├── assets/site-card.svg  # 社交分享预览图
├── _config.yml           # GitHub Pages / Jekyll 配置
└── Gemfile               # 本地预览用，可选
```

## 日常维护

### 1. 修改个人信息

打开 `index.md` 顶部的 YAML 区域：

```yaml
name: "Yixin Tao"
role: "Assistant Professor"
affiliation: "Institute for Theoretical Computer Science, Shanghai University of Finance and Economics"
email: "taoyixin@mail.shufe.edu.cn"
```

改完保存并提交即可。

### 2. 修改 About / Research

直接在 `index.md` 中修改 Markdown 内容：

```md
## About
{: #about }

I am an Assistant Professor ...

## Research interests
{: #research }

- **Algorithmic Game Theory.** ...
- **Market Equilibrium.** ...
- **Optimization.** ...
```

标题下面的 `{: #about }`、`{: #research }` 是锚点 ID，建议保留，这样导航菜单可以正常跳转。

### 3. 新增论文

在 `index.md` 的 `### Journal and conference papers` 或 `### Working papers` 下复制一条论文格式：

```md
1. **[Paper Title](https://paper-link.example)**  
   Author A, Author B, and Yixin Tao.  
   _Venue, Year._
```

注意：标题行和作者行末尾有两个空格，用于在 Markdown 中换行。

论文搜索功能会自动读取 Markdown 渲染后的论文列表，不需要修改 `script.js`。

## 发布到 GitHub Pages

如果继续使用 `tomtao26.github.io` 这个仓库：

1. 解压本 ZIP。
2. 把里面所有文件上传到仓库根目录。
3. 确认根目录中直接包含：`index.md`、`_layouts/`、`assets/`、`_config.yml`。
4. 在 GitHub 网页端编辑 `index.md`，commit 后 GitHub Pages 会自动重新构建。

## 本地预览，可选

如果电脑已经装好 Ruby，可以运行：

```bash
bundle install
bundle exec jekyll serve
```

然后浏览器打开：

```text
http://localhost:4000
```

如果不想配置本地环境，直接在 GitHub 上编辑 `index.md` 并提交即可，GitHub Pages 会负责渲染。

## 改颜色

打开 `assets/styles.css`，修改顶部变量：

```css
:root {
  --primary: #1d4ed8;
  --accent: #0f766e;
  --bg: #f8fafc;
}
```

一般只改这三个变量就足够。
