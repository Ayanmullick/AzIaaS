| Resource Type                                           | Domain                  | Business | Roles | Location | Environment | ResourceType | Seq# | Example                 |
| ------------------------------------------------------- | ----------------------- | -------- | ----- | -------- | ----------- | ------------ | ---- | ----------------------- |
| Subscription                                            |                         |          |       |          |             |              |      | SubAIPoC                |
| Resource group                                          | 3                       | 3        |       | 1-2      | 1-2         | 2            | 1-2  | EcmSaiE2DRg1            |
| AI Foundry \| Azure AI hub                              | 2                       | 3        |       | 1-2      | 1-2         | 2            | 1-2  | EcmSaiE2DAif1           |
| AI Foundry Project\| Azure AI project                   | 2                       | 3        | 3-10  | 1-2      | 1-2         | 4            | 0    | EcmSaiPolicyBotE2DAifp1 |
| Cognitive Services\|  AI services multi-service account | 2                       | 3        |       | 1-2      | 1-2         | 2            | 0    | EcmSaiE2DCs1            |
| Search service                                          | 2                       | 3        |       | 1-2      | 1-2         | 2            | 1-2  | EcmSaiE2DSs1            |
|                                                         |                         |          |       |          |             |              |      |                         |
| Log Analytics workspace                                 | 2                       | 3        |       | 1-2      | 1-2         | 3            | 1-2  | EcmSaiE2DLaw1           |
| Application Insights                                    | Log Analytics workspace |          |       |          |             | 2            |      | EcmSaiE2DLaw1Ai         |
| User Assigned Identities                                | 2                       | 3        |       | 1-2      | 1-2         | 4            | 1-2  | EcmSaiE2DUami1          |
| Storage Account                                         | 2                       | 3        |       | 1-2      | 1-2         | 2            | 1-2  | ecmsaie2dsa1            |
| Blob container name                                     | Storage Account         |          |       |          |             | 2            | 1-2  | ecmsaie2dsa1bc          |
| Distribution List for Teams apps                        | 2                       | 3        |       |          |             | 2            |      | EcmSaiDL                |
| Fabric Capacity                                         |                         |          | 3-10  | 1-2      | 1-2         | 2            |      | InfraBoardsE2DFc        |