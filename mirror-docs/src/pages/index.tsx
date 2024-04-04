import React from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Translate, { translate } from "@docusaurus/Translate";

import styles from "./index.module.css";
import { initPostHog } from "../analytics/posthog";

// Init analytics
initPostHog();

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <img src="img/white_transparent_logo.png" width={600}></img>
        <h1 style={{ marginTop: 15, marginBottom: 20 }}>
          <Translate
            id="homepage.title1"
            description="The main title on the homepage"
          >
            Freedom to Own
          </Translate>
        </h1>
        <h1 style={{ marginTop: 0, marginBottom: 30 }}>
          <Translate
            id="homepage.title2"
            description="The subtitle on the homepage"
          >
            The Open-Source Roblox & UEFN Alternative
          </Translate>
        </h1>
        <div className={styles.buttons}>
          <Link
            className="button mirror-success-button button--lg"
            to="/docs/get-started"
            style={{ marginRight: "15px" }}
          >
            <Translate
              id="homepage.appDocsButton"
              description="Button label for app docs"
            >
              App Docs
            </Translate>
          </Link>
          <Link
            className="button mirror-success-button button--lg"
            to="/docs/open-source-code/get-started"
          >
            <Translate
              id="homepage.openSourceDocsButton"
              description="Button label for open-source docs"
            >
              Open-Source Docs
            </Translate>
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${translate({
        id: "homepage.layoutTitle",
        message: "Docs",
        description: "The title tag for the homepage layout",
      })}`}
      description={translate({
        id: "homepage.layoutDescription",
        message: "Game Development Platform: The Ultimate Sandbox",
        description: "The description tag for the homepage layout",
      })}
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
