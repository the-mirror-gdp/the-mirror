import React from "react";
import clsx from "clsx";
import styles from "./styles.module.css";
import Translate, { translate } from "@docusaurus/Translate";

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<"svg">>;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: translate({
      message: "Physics Sandbox",
      description: "The title for the Physics Sandbox feature",
    }),
    Svg: require("@site/static/img/undraw_docusaurus_mountain.svg").default,
    description: (
      <Translate
        id="feature.physics-sandbox.description"
        description="Description for the Physics Sandbox feature"
      >
        Building a multiplayer game is hard! The Mirror makes this easy. You're
        the creator, the developer, the designer, and the architect of your
        Mirror Space.
      </Translate>
    ),
  },
  {
    title: translate({
      message: "Co-Build with Friends",
      description: "The title for the Co-Build with Friends feature",
    }),
    Svg: require("@site/static/img/undraw_docusaurus_react.svg").default,
    description: (
      <Translate
        id="feature.co-build-with-friends.description"
        description="Description for the Co-Build with Friends feature"
      >
        With Godot, the Mirror offers real-time game development with seamless
        transitions between building and playing, knit together with
        out-of-the-box networking, payments, authentication, publishing, and
        more.
      </Translate>
    ),
  },
  {
    title: translate({
      message: "Monetize",
      description: "The title for the Monetize feature",
    }),
    Svg: require("@site/static/img/undraw_docusaurus_tree.svg").default,
    description: (
      <Translate
        id="feature.monetize.description"
        description="Description for the Monetize feature"
      >
        The Mirror is your platform to make a living off your passion for game
        development and 3D modeling. Monetize interoperable creations with the
        click of a button.
      </Translate>
    ),
  },
];

function Feature({ title, Svg, description }: FeatureItem) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
