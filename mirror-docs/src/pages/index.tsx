import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import styles from './index.module.css';
import { initPostHog } from '../analytics/posthog';

// Init analytics
initPostHog()

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <img src="img/white_transparent_logo.png" width={600}></img>
        <h1 style={{ marginTop: 15, marginBottom: 20 }} >Freedom to Own</h1>
        <h1 style={{ marginTop: 0, marginBottom: 30 }} >The Open-Source Roblox & UEFN Alternative</h1>
        <div className={styles.buttons}>
          <Link
            className="button mirror-success-button button--lg"
            to="/docs/get-started" style={{ marginRight: '15px' }}>
            App Docs
          </Link>
          <Link
            className="button mirror-success-button button--lg"
            to="/docs/open-source-code/get-started">
            Open-Source Docs
          </Link>
        </div>
      </div>
    </header >
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`Docs`}
      description="Game Development Platform: The Ultimate Sandbox">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
