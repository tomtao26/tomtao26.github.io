---
layout: page
title : Research
header : Research Topics
group: navigation
---
{% include JB/setup %}

### Research Interests

My research interests are mobile systems and virtualization.

- - -

### Research Projects

#### Mobile

Mobile platforms like smartphones have unique features like scarce computing, storage and power resources, high possible to physical attacks and lost. These usually render traditional measures for desktop and servers not directly applicable. The following projects aim at hardening mobile systems using various approaches.

* **PreCrime** :
Since suspicious apps are constantly evolving to bypass present detecting techniques, it becomes harder for nowadays measures to prevent abnormal behavior from hap- pening. We propose a speculative execution framework called PreCrime, which is deployed on cloud to explore the possible paths one step ahead of the smartphone.

* **TinMan**:
Device theft and loss expose smartphones not only to software attacks, but also to physical threats. TinMan is a cloud-based system that eliminates the exposure of confidential data from mobile devices by utilizing program offloading and asymmetric taint tracking. I designed and implemented the asymmetric taint tracking part of RoseCloud.

* **EventChain**:
Permission system are the most commonly used security system in commodity smartphones. EventChain is a behavior-based permission granting system which targets improving drawbacks of app-based permission granting mechanism. 

* **ReDroid**:
Market release model and repackaged applications make the suspicious apps easy to spread and hard to spot. Since malware is hard to eliminate, how to do post-mortem auditing and recovery of the damage caused becomes a key research challenge. We design and implement ReDroid, an event-centric record and replay framework, to track the applications’ operations with little overhead. By replaying a malware-free version of the application, ReDroid can analyze the different behavior between record and replay and repair the data generated from benign operations.

####Nested Virtuliaztion

Along with the rapid development of virtualization technology, lots of new features are added to the hypervisor which inflates its code size and brings bugs and vul- nerabilities. Nested virtualization systems are built beneath virtualization layer to mitigate these threats.

* **TinyChecker**:With the expansion of the code size, hypervisors are more likely to crash. To survive the guest VMs from a crashed hypervisor, we design TinyChecker, a very small soft- ware layer designated for transparent failure detection and recovery. By recording the entire communication context between VM and hypervisor, TinyChecker can protect the critical VM data, detect and recover the hypervisor among failures.

* **CloudVisor**: 
With overstaffed software stack, clouds are vulnerable from adversaries including the cloud operators, which may lead to leakage of sensitive data. CloudVisor is a tiny monitor underneath the commodity VMM using nested virtualization and provides protection to the hosted VMs. I helped in building the final version of CloudVisor and implemented the automatic PCI-device detector and secure live migration module with emulated NIC. 



- - -

### Publications

- Yubin Xia, Yutao Liu, **Cheng Tan**, and Mingyang Ma, Haibing Guan, Binyu Zang and Haibo Chen. TinMan: Eliminating Confidential Mobile Data Exposure with Security-oriented Offloading. (Eurosys 2015)

- **Cheng Tan**, Haibo Li, Yubin Xia, Binyu Zang, Cheng-Kang Chu, Tieyan Li, Feng Bao. PreCrime to the Rescue: Defeating Mobile Malware One Step Ahead. (Apsys 2014)

- **Cheng Tan**, Yubin Xia, Haibo Chen, Binyu Zang. TinyChecker: Transparent Protection Of VMs Against Hypervisor Failures With Nested Virtualization. The Second International Workshop on Dependability of Clouds, Data Centers and Virtual Machine Technology ( DCDV 2012)

- Songchun Fan, **Cheng Tan** , Xin Fan, Han Su, and Jinyu Zhang. HeartPlayer: A Smart Music Player Involving Emotion Recognition, Expression and Recommendation. In Proceedings of the 17th international conference on Advances in multimedia modeling ( *Demo* MMM 2011)
