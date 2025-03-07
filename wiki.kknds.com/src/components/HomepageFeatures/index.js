import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [


  {
    title: 'guides, info, and recipes',
    Svg: require('@site/static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>

          <div className={styles.warning}>
              <strong>Disclaimer:</strong> The information presented throughout this wiki is provided "as is"
              and without warranty of any kind, express or implied.
              While the information provided is believed to be correct,
              it may include errors or inaccuracies. Use it at your own risk!
          </div>

      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--8')}>

      <div className="text--center padding-horiz--md">

        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row" style={{display: 'flex', justifyContent: 'center'}}>
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
