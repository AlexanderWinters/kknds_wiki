// src/pages/index.js
import React, { useState, useEffect } from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import styles from './index.module.css';

export default function NewHomePage() {
    const {siteConfig} = useDocusaurusContext();
    const [isVisible, setIsVisible] = useState(false);

    // Trigger animations when component mounts
    useEffect(() => {
        setIsVisible(true);
    }, []);

    return (
        <Layout
            title={siteConfig.title}
            description="KKNDS Wiki - guides, info, and recipes">
            <div className={styles.container}>
                <header className={styles.header}>
                    <h1 className={styles.title}>{siteConfig.title}</h1>
                    <p className={styles.subtitle}>{siteConfig.tagline}</p>
                </header>

                <main className={styles.main}>
                    <div className={styles.ctaContainer}>
                        <Link to="/docs/linux/wiki" className={styles.ctaButton}>
                            Explore Documentation
                        </Link>
                    </div>

                    <div className={styles.disclaimer}>
                        <p>
                            <strong>Disclaimer:</strong> The information presented throughout this wiki is provided "as is"
                            and without warranty of any kind, express or implied.
                            While the information provided is believed to be correct,
                            it may include errors or inaccuracies. Use it at your own risk!
                        </p>
                    </div>
                </main>
            </div>
        </Layout>
    );
}