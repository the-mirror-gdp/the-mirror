// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const themes = require('prism-react-renderer').themes;
const lightCodeTheme = themes.github;
const darkCodeTheme = themes.dracula;
const darkTheme = themes.vsDark;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'The Mirror',
  tagline: 'Open-Source Roblox & UEFN Alternative',
  url: 'https://docs.themirror.space',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'the-mirror-gdp', // Usually your GitHub org/user name.
  projectName: 'The Mirror: Docs', // Usually your repo name.

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
        },
        blog: {
          showReadingTime: true,
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        // title: 'The Mirror',
        logo: {
          alt: 'The Mirror Logo',
          src: 'img/white_transparent_logo.png',
        },
        items: [
          {
            href: 'https://in.themirror.space',
            position: 'left',
            label: 'In The Mirror'
            // className: 'header-github-link',
            // 'aria-label': 'GitHub repository',
          }
          // { to: '/blog', label: 'Blog', position: 'left' },
        ],
      },
      metadata: [
        { name: 'title', content: 'Docs | The Mirror' },
        { name: 'og:title', content: 'Docs | The Mirror' },
        { name: 'og:url', content: 'https://docs.themirror.space/' },
        { name: 'og:image', content: 'https://docs.themirror.space/img/DocsSite.jpg' },
        { name: 'description', content: 'Game Development Platform: The Ultimate Sandbox' },
        { name: 'og:description', content: 'Game Development Platform: The Ultimate Sandbox' },
        { name: 'twitter:title', content: 'Docs | The Mirror' },
        { name: 'twitter:description', content: 'Game Development Platform: The Ultimate Sandbox' },
        { name: 'twitter:image', content: 'https://docs.themirror.space/img/DocsSite.jpg' },
        { name: 'twitter:card', content: 'https://docs.themirror.space/img/DocsSite.jpg' },
      ],
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Social',
            items: [
              {
                label: 'Discord',
                href: 'https://themirror.space/discord',
              },
              {
                label: 'Reddit',
                href: 'https://reddit.com/r/themirrorspace',
              },
              {
                label: 'Twitter',
                href: 'https://twitter.com/themirrorgdp',
              },
              {
                label: 'Instagram',
                href: 'https://instagram.com/themirrorgdp',
              },
              {
                label: 'LinkedIn',
                href: 'https://www.linkedin.com/company/the-mirror-megaverse',
              },
            ],
          },
          {
            title: 'Download',
            items: [

              {
                label: 'Itch.io: The Mirror',
                href: 'https://themirrorgdp.itch.io/the-mirror',
              },
            ],
          },
          {
            title: 'About',
            items: [

              {
                label: 'Home',
                href: 'https://themirror.space',
              },
              {
                label: 'Blog',
                href: 'https://themirror.space/blog',
              },
              {
                label: 'Features',
                href: 'https://themirror.space/features',
              },
              {
                label: 'Open-Source Licenses',
                href: 'https://www.notion.so/the-mirror/Open-Source-License-Credits-Public-8a3e0d75682b48d7bfaa3518f4b5caaf',
              },
            ],
          },

        ],
        copyright: `Copyright © ${new Date().getFullYear()} The Mirror Megaverse, Inc. | We ❤️ Open-Source: Built with <a href="https://github.com/facebook/docusaurus" target="_blank">Docusaurus</a>`,
      },
      colorMode: {
        defaultMode: 'dark',
        disableSwitch: true,
        respectPrefersColorScheme: false
      },
      announcementBar: {
        id: 'alpha_notice',
        content:
          '<b>&#11088; <a rel="noopener noreferrer" href="https://github.com/the-mirror-gdp/the-mirror" target="_blank">Star on Github!</a> The Mirror is now open-source, MIT-licensed.</b>',
        backgroundColor: '#00CFFF',
        textColor: '#06011F',
        isCloseable: true,
      },
      algolia: {
        // The application ID provided by Algolia
        appId: 'WZDUGEW4O1',

        // Public API key: it is safe to commit it
        apiKey: 'cee727fb358dbae0ef4cb1c3f4b1da52',

        indexName: 'themirror',

        // Optional: see doc section below
        contextualSearch: true,

        // Optional: Specify domains where the navigation should occur through window.location instead on history.push. Useful when our Algolia config crawls multiple documentation sites and we want to navigate with window.location.href to them.
        externalUrlRegex: 'themirror.space|docs.themirror.space',

        // Optional: Replace parts of the item URLs from Algolia. Useful when using the same search index for multiple deployments using a different baseUrl. You can use regexp or string in the `from` param. For example: localhost:3000 vs myCompany.com/docs
        replaceSearchResultPathname: {
          from: '/docs/', // or as RegExp: /\/docs\//
          to: '/',
        },

        // Optional: Algolia search parameters
        searchParameters: {},

        // Optional: path for search page that enabled by default (`false` to disable it)
        searchPagePath: 'search',

        // Optional: whether the insights feature is enabled or not on Docsearch (`false` by default)
        insights: true,

        //... other Algolia params
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: {
          plain: {
            color: '#D4D4D4',
            backgroundColor: '#1F1C36',
          },
          styles: [
            {
              types: ["prolog"],
              style: {
                color: "rgb(0, 0, 128)"
              }
            }, {
              types: ["comment"],
              style: {
                color: "rgb(106, 153, 85)"
              }
            }, {
              types: ["builtin", "changed", "keyword", "interpolation-punctuation"],
              style: {
                color: "rgb(86, 156, 214)"
              }
            }, {
              types: ["number", "inserted"],
              style: {
                color: "rgb(181, 206, 168)"
              }
            }, {
              types: ["constant"],
              style: {
                color: "rgb(100, 102, 149)"
              }
            }, {
              types: ["attr-name", "variable"],
              style: {
                color: "rgb(156, 220, 254)"
              }
            }, {
              types: ["deleted", "string", "attr-value", "template-punctuation"],
              style: {
                color: "rgb(206, 145, 120)"
              }
            }, {
              types: ["selector"],
              style: {
                color: "rgb(215, 186, 125)"
              }
            }, {
              // Fix tag color
              types: ["tag"],
              style: {
                color: "rgb(78, 201, 176)"
              }
            }, {
              // Fix tag color for HTML
              types: ["tag"],
              languages: ["markup"],
              style: {
                color: "rgb(86, 156, 214)"
              }
            }, {
              types: ["punctuation", "operator"],
              style: {
                color: "rgb(212, 212, 212)"
              }
            }, {
              // Fix punctuation color for HTML
              types: ["punctuation"],
              languages: ["markup"],
              style: {
                color: "#808080"
              }
            }, {
              types: ["function"],
              style: {
                color: "rgb(37, 107, 251)"
              }
            }, {
              types: ["class-name"],
              style: {
                color: "rgb(78, 201, 176)"
              }
            }, {
              types: ["char"],
              style: {
                color: "rgb(209, 105, 105)"
              }
            },
            {
              types: ['title'],
              style: {
                color: '#569CD6',
                fontWeight: 'bold',
              },
            },
            {
              types: ['property', 'parameter'],
              style: {
                color: '#9CDCFE',
              },
            },
            {
              types: ['script'],
              style: {
                color: '#D4D4D4',
              },
            },
            {
              types: ['boolean', 'arrow', 'atrule', 'tag'],
              style: {
                color: '#569CD6',
              },
            },
            {
              types: ['number', 'color', 'unit'],
              style: {
                color: '#B5CEA8',
              },
            },
            {
              types: ['font-matter'],
              style: {
                color: '#CE9178',
              },
            },
            {
              types: ['keyword', 'rule'],
              style: {
                color: '#C586C0',
              },
            },
            {
              types: ['regex'],
              style: {
                color: '#D16969',
              },
            },
            {
              types: ['maybe-class-name'],
              style: {
                color: '#4EC9B0',
              },
            },
            {
              types: ['constant'],
              style: {
                color: '#4FC1FF',
              },
            },
          ],
        },
      },
    }),
  // https://github.com/cmfcmf/docusaurus-search-local#usage
  plugins: [
    [
      require.resolve("@cmfcmf/docusaurus-search-local"),
      {
        style: undefined
      }
    ],
  ],
};

module.exports = config;
